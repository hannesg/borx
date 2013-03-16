begin
  require 'ripper'
rescue NotFound
  raise NotFound, "Ripper extension not found. Please add it to your bundle."
end
require 'sorcerer'
require 'borx/code'
class Borx::Rewriter < Ripper::SexpBuilder

  # @api private
  ARGS_NEW = [:args_new].freeze

  def self.rewrite(code, options = {})
    tree = self.new(code).parse
    code = Sorcerer.source(tree, options)
    return Borx::Code.new(code)
  end

private

  def on_top_const_ref(*args)
    ref = super
    return call_borx('get_constant',
                       [:args_add,
                         [:args_add, ARGS_NEW, ident_to_string(ref[1])],
                         [:@const, "Object", [0,0]]])
  end


  def on_const_path_ref(*args)
    path = super
    return call_borx('get_constant',[:args_add, [:args_add, ARGS_NEW, ident_to_string(path[2])], path[1]])
  end

  def on_method_add_arg(*x)
    name, call, args, block = super
    inject_binding = true
    if call[0] ==  :fcall
      args = args[1][1] unless args == ARGS_NEW
      brgs = push_args(args,[:var_ref, [:@kw, "self", [0, 0]]],ident_to_string(call[1]))
      return call_borx('call_private_method', brgs)
    elsif call[0] == :method_add_arg
      # this case doesn't show up in the wild
      # it exists because of the way we rewrite calls
      inject_binding = false
      brgs = push_args(args[1][1], call[2][1][1])
    else
      # :nocov:
      raise "Unknown call type #{call}. This is bug. Please report it"
      # :nocov:
    end
    return call_borx('call_method', brgs, binding: inject_binding)
  end

  def on_call(*args)
    call = super
    return call_borx('call_method',
                     [:args_add,
                       [:args_add,[:args_new],call[1]],
                       ident_to_string(call[3])])
  end

  def on_vcall(vcall)
    s = super
    return call_borx('get_variable', [:args_add, [:args_new], ident_to_string(s[1])])
  end

  def on_var_ref(x)
    var = super
    fun = case(var[1][0])
            when :@const then 'get_constant'
            when :@gvar  then 'get_global_variable'
            when :@cvar  then 'get_class_variable'
            when :@ivar  then 'get_instance_variable'
            when :@ident then 'get_variable'
            when :@kw    then 'get_magic'
            # :nocov:
            else
              raise "Unknown var_ref type in #{var[1]}, this is a bug, please report it"
            # :nocov:
          end
    return call_borx(fun, [:args_add, [:args_new], ident_to_string(var[1])])
  end

  def on_assign(field, value)
    assign, field, value = super
    if field[0] == :var_field
      fun = case(field[1][0])
              when :@const then 'set_constant'
              when :@gvar  then 'set_global_variable'
              when :@cvar  then 'set_class_variable'
              when :@ivar  then 'set_instance_variable'
              when :@ident then 'set_variable'
              # :nocov:
              else
                raise "Unknown var_field type in #{var[1]}, this is a bug, please report it"
              # :nocov:
            end
      return call_borx(fun,
                        [:args_add,
                          [:args_add, [:args_new],
                            ident_to_string(field[1])], value])
    elsif field[0] == :field
      return call_borx('call_method',
                            [:args_add,
                              [:args_add,
                                [:args_add,[:args_new],field[1]], 
                                [:string_literal,[:string_add,[:string_content],[:@tstring_content,field[3][1]+"=",field[3][2]]] ]
                              ], value
                            ])
    elsif field[0] == :const_path_field
      return call_borx('set_constant',
                            [:args_add,
                              [:args_add,
                                [:args_add,[:args_new],ident_to_string(field[2])], 
                                field[1]
                              ], value
                            ])
    elsif field[0] == :top_const_field
      return call_borx('set_constant',
                            [:args_add,
                              [:args_add,
                                [:args_add, [:args_new],
                                  ident_to_string(field[1])],
                                  [:@const, 'Object',[0,0]]
                              ], value])
    end
    # :nocov:
    raise "Unknown assign type #{field}. This is a bug. Please report it"
    # :nocov:
  end

  def on_xstring_literal(x)
    x = super
    return call_borx('execute', [:args_add, [:args_new], xstring_to_string(x)])
  end

  def on_method_add_block(args, block)
    name, args, block = super
    pp args, block
    new_vars = [:args_new]
    if block[1]
      block[1][1][1].each do |arg|
        next unless arg
        new_vars = [:args_add, new_vars, ident_to_string(arg)]
      end
    end
    new_block = [:method_add_block,
     [:method_add_arg,
      [:call,
       [:var_ref, [:@ident, "__borx_binding__", [0, 0]]],
       :".",
       [:@ident, "block", [0, 0]]],
      [:arg_paren,
       [:args_add_block,
        new_vars,
        false]]],
     [:brace_block,
      [:block_var,
        [:params, [[:@ident, "__borx_binding__", [1, 20]]], nil, nil, nil, nil, nil, nil],
        false],
      block[2]]
    ]

    return put_args_add_block(args,new_block)
  end

  def put_args_add_block(args, block)
    if args[0] == :args_add_block
      return [:args_add_block, args[1], block]
    elsif args[0] == :method_add_arg
      return [:method_add_arg, args[1], put_args_add_block(args[2],block)]
    elsif args[0] == :arg_paren
      return [:arg_paren, put_args_add_block(args[1],block)]
    end
    raise "boom"
  end

  def xstring_to_string(x)
    if x[0] == :xstring_literal
      return [:string_literal, xstring_to_string(x[1]), *x[2..-1]]
    elsif x[0] == :xstring_add
      return [:string_add, xstring_to_string(x[1]), *x[2..-1]]
    elsif x[0] == :xstring_new
      return [:string_content]
    else
      # :nocov:
      raise "Unknown xstring type #{x}. This is a bug. Please report it."
      # :nocov:
    end
  end

  def call_borx(name,args, options = {})
    args = push_args(args, binding_args) unless options[:binding] == false
    return [:method_add_arg,
      [:call, [:var_ref, [:@ident, "__borx__", [0, 0]]], :'.', [:@ident, name, [0,0]]],
      [:arg_paren,
        [:args_add_block,
         args,
         options.fetch(:block, false)
        ]
      ]
    ]
  end

  def binding_args
    return [:var_field, [:@ident, "__borx_binding__", [1, 0]]]
  end

  def ident_to_string(ident)
    [:string_literal,
      [:string_add,[:string_content],
        [:@tstring_content, ident[1], ident[2]]]]
  end

  def push_args(tree, *args)
    if tree == [:args_new]
      if args.any?
        return [:args_add, push_args(tree, *args[0..-2]), args.last]
      else 
        return tree
      end
    else
      return [:args_add, push_args(tree[1], *args), tree[2]]
    end
  end

end

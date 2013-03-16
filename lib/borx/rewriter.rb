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
=begin
  def on_stmts_new
    return [:stmts_add,
        [:stmts_new],
        [:assign,
           [:var_field, [:@ident, "__borx_binding__", [1, 0]]],
                  [:call,
                        [:var_ref, [:@ident, "__borx_binding__", [1, 19]]],
                            :".",
                                [:@ident, "child", [1, 36]]]]]
    return [:stmts_add, [:stmts_new], [:assign,
            [:var_field, [:@ident, "__borx_binding__", [1, 0]]],
              [[:vcall, [:@ident, "binding", [1, 17]]]]]]
  end
=end
=begin
  def on_brace_block(block_var, stmts)
    name, block_var, stmts = super
    return [name, block_var, [:stmts_add,
  [:stmts_new],
  [:method_add_arg,
   [:call,
    [:method_add_block,
     [:method_add_arg, [:fcall, [:@ident, "proc", [1, 0]]], [:args_new]],
     [:brace_block,
      [:block_var,
       [:params,
        [[:@ident, "__borx_binding__", [1, 6]]],
        nil,
        nil,
        nil,
        nil,
        nil,
        nil],
       false],
      stmts]],
    :".",
    [:@ident, "call", [1, 28]]],
   [:arg_paren,
    [:args_add_block,
     [:args_add,
      [:args_new],
      [:call,
       [:vcall, [:@ident, "__borx_binding__", [1, 33]]],
       :".",
       [:@ident, "child", [1, 50]]]],
     false]]]]]
  end
=end
  
  def on_method_add_block(args, block)
    name, args, block = super
    pp args, block
    new_vars = [:args_new]
    if block[1]
      
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
    return [name, args, new_block]
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

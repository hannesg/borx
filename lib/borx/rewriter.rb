require 'ripper'
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
  def on_var_ref(*args)
    ref = super
    if ref[1][0] == :@const
      return call_borx('get_constant',[:args_add, ARGS_NEW, ident_to_string(ref[1])])
    else
      return ref
    end
  end

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
      brgs = push_args(args[1][1],call[1],ident_to_string(call[3]))
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
    return [assign, field, value]
  end

  def on_xstring_literal(x)
    x = super
    return call_borx('execute', [:args_add, [:args_new], xstring_to_string(x)])
  end

  def on_stmts_new
    return [:stmts_add, [:stmts_new], [:assign,
            [:var_field, [:@ident, "__borx_binding__", [1, 0]]],
              [:vcall, [:@ident, "binding", [1, 17]]]]]
  end

  def xstring_to_string(x)
    if x[0] == :xstring_literal
      return [:string_literal, *x[1..-1]]
    elsif x[0] == :xstring_add
      return [:string_add, *x[1..-1]]
    elsif x[0] == :xstring_new
      return [:string_new]
    else
      return x
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
    #[:vcall,[:@ident, 'binding',[0,0]]]
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

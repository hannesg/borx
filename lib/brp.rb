require 'pp'
require 'ripper'
gem 'sorcerer'
require 'sorcerer'

class BRP

  class B < Ripper::SexpBuilder

    def on_var_ref(*args)
      ref = super
      if ref[1][0] == :@const
        return call_sandbox('get_constant',[:args_add_block, [:args_add,[:args_new], ident_to_string(ref[1])], false])
      else
        return ref
      end
    end

    def on_const_path_ref(*args)
      path = super
      return call_sandbox('get_constant',[:args_add_block, [:args_add, [:args_add,[:args_new], ident_to_string(path[2])], path[1]],false])
    end

    def on_method_add_arg(call, args)
      name, call, args = super
      if call[0] ==  :fcall
        brgs = push_args(args[1][1],[:var_ref, [:@kw, "self", [0, 0]]],ident_to_string(call[1]))
      elsif call[0] == :method_add_arg
        # this case doesn't show up in the wild
        # it exists because of the way we rewrite calls
        brgs = push_args(args[1][1], call[2][1][1])
      else
        brgs = push_args(args[1][1],call[1],ident_to_string(call[3]))
      end
      return [:method_add_arg,
               [:call, [:var_ref, [:@ident, "__sandbox__", [0, 0]]], :'.', [:@ident, "call_method", [0,0]]],
               [:arg_paren,
                 [:args_add_block,
                   brgs,
                   false
                  ]
              ]]
    end

    def on_call(*args)
      call = super
      return call_sandbox('call_method', [:args_add_block, [:args_add, [:args_add,[:args_new],call[1]], ident_to_string(call[3])]])
    end

    def on_vcall(vcall)
      s = super
      return call_sandbox('get_variable', [:args_add_block, [:args_add, [:args_add, [:args_new], [:vcall,[:@ident, 'binding',[0,0]]] ], ident_to_string(s[1])], false] )
    end

    def on_assign(field, value)
      assign, field, value = super
      if field[0] == :var_field
        return call_sandbox('set_variable',
                            [:args_add_block,
                              [:args_add,[:args_add, [:args_add, [:args_new], [:vcall,[:@ident, 'binding',[0,0]]] ], ident_to_string(field[1])], value],
                              false
                            ] )
      elsif field[0] == :field
        return call_sandbox('call_method',
                            [:args_add_block,
                              [:args_add,
                                [:args_add,
                                  [:args_add,[:args_new],field[1]], 
                                  [:string_literal,[:string_add,[:string_content],[:@tstring_content,field[3][1]+"=",field[3][2]]] ]
                                ], value
                              ],
                              false
                            ])
      elsif field[0] == :const_path_field
        return call_sandbox('set_constant',
                            [:args_add_block,
                              [:args_add,
                                [:args_add,
                                  [:args_add,[:args_new],ident_to_string(field[2])], 
                                  field[1]
                                ], value
                              ],
                              false
                            ])
      end
      return [assign, field, value]
    end

    def call_sandbox(name,args)
      [:method_add_arg,
        [:call, [:var_ref, [:@ident, "__sandbox__", [0, 0]]], :'.', [:@ident, name, [0,0]]],
        [:arg_paren,
           args
        ]
      ]
    end

    def ident_to_string(ident)
      [:string_literal,[:string_add, [:string_content],[:@tstring_content, ident[1], ident[2]]]]
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



  def self.parse(code, *args)
    tree = B.new(code).parse
  end

end

base = Class.new do

  def get_constant(name, house = nil)
    raise Sandbox::NotImplemented::GetConstant
  end

  def set_constant(name, house = nil, value)
    raise Sandbox::NotImplemented::SetConstant
  end

  def call_method(receiver, name, *args, &block)
    raise Sandbox::NotImplemented::CallMethod
  end

  def get_variable(bindink, name)
    raise Sandbox::NotImplemented::GetVariable
  end

  def set_variable(bindink, name, value)
    raise Sandbox::NotImplemented::SetVariable
  end

end

class Sandbox < base

  Base = superclass

  module GetVariable

    def get_variable(binding, name)
      binding.eval(name)
    end

  end

  module SetVariable


  end

  module GetSetVariable
    include GetVariable
  end

  module CallMethod
    def call_method(receiver, name ,*args, &block)
      receiver.__send__(name, *args, &block)
    end
  end

  module GetConstant
    def get_constant(name, house = Object)
      house.const_get(name)
    end
  end

  module GetSetConstant
    include GetConstant
  end

  include GetSetVariable
  include GetSetConstant
  include CallMethod

  class NotImplemented < StandardError
    class GetConstant < self
    end
    class SetConstant < self
    end
    class CallMethod < self
    end
    class GetVariable < self
    end
    class SetVariable < self
    end
  end

  def eval(code)

  end

  def eval_(code, binding, file = '(eval)', line = 0)
    old_sandbox, setter = binding.eval('__sandbox__ ||= nil ; [__sandbox__, lambda{|v| __sandbox__ = v}]')
    setter.call(self)
    binding.eval(code, file, line)
  ensure
    setter.call(old_sandbox) if setter
  end

end

a = 10

def foo(name, x, y)
  puts "#{name} = #{x * y}"
end

tree = BRP.parse("foo('b',2, a)\n IO::FOO.bar\n Foo.bar\n a = 1\nb.a = 1\nFoo::BAR = 3\nIO.read(File.join(File.dirname(__FILE__),'README.md'))")
code = Sorcerer.source(tree, multiline: true)
Sandbox.new.eval_(code, binding)
puts __sandbox__

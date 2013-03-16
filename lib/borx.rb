module Borx

  def self.Binding(binding = nil)
    if binding.kind_of? ::Binding
      return Binding::Adapter.new(binding)
    elsif binding.kind_of? Binding
      return binding
    elsif binding.nil?
      return Binding::Terminal.new
    else
      raise ArgumentError, "Expected a Binding, got #{binding.inspect}"
    end
  end

end

require 'borx/environment'
require 'borx/rewriter'
require 'borx/binding'

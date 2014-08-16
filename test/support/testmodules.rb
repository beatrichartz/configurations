module TestModules

  def testmodule_for(mod)
    a = Module.new
    a.module_eval { include mod }

    a
  end

end

module ProjectsHelper
  def plan_options(project)
    if plan = project.plan
      options = plan.options
      "The <strong>#{plan.name}</strong> plan allows up to #{options[:users]} coders, #{options[:sources]} sources and #{options[:documents]} documents." if options
    end
  end
end

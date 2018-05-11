class Admin::TasksController < Admin::AdminController
  before_action :require_sysadmin
  before_action :redirect_to_tasks_tab, if: :missing_tasks?

  def create
    if Admin::TaskRunner.run(params)
      notice = [:started_tasks, count: selected_tasks.size]
    else
      notice = [:failed_tasks]
    end

    redirect_to edit_admin_site_path(tab: "tasks"), notice: notice
  end

  private

  def redirect_to_tasks_tab
    redirect_to edit_admin_site_path(tab: "tasks"), notice: :missing_tasks
  end

  def missing_tasks?
    selected_tasks.empty?
  end

  def selected_tasks
    Array(params[:tasks])
  end
end

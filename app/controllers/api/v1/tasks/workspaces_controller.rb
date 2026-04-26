class API::V1::Tasks::WorkspacesController < API::V1::Tasks::BaseController
  def show
    render_data(API::V1::Serializers.task_workspace(
      tasks_root_folder,
      projects_folder: task_projects_folder,
      projects: project_folders_scope.to_a
    ))
  end
end

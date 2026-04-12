class Notes::BaseController < ApplicationController
  include NotesHelper

  helper_method :current_product_area, :notes_root_folder, :notes_subtree_folders, :notes_folder_options

  private

  def current_product_area
    :notes
  end

  def notes_root_folder
    @notes_root_folder ||= Current.user.folders.find_or_create_by!(parent_id: nil, name: "Notes") do |folder|
      folder.source = :local
      folder.metadata = {"app" => "notes", "role" => "root"}
    end
  end

  def all_user_folders
    @all_user_folders ||= Current.user.folders.order(:name).to_a
  end

  def notes_subtree_folders
    @notes_subtree_folders ||= begin
      children_by_parent = all_user_folders.group_by(&:parent_id)
      folders = [notes_root_folder]
      queue = Array(children_by_parent[notes_root_folder.id])

      until queue.empty?
        folder = queue.shift
        folders << folder
        queue.concat(Array(children_by_parent[folder.id]))
      end

      folders
    end
  end

  def notes_folder_ids
    notes_subtree_folders.map(&:id)
  end

  def notes_files_scope
    Current.user.stored_files.includes(:blob, :folder).where(folder_id: notes_folder_ids, mime_type: "text/markdown")
  end

  def notes_folder_options
    notes_folder_options_for(notes_root_folder, notes_subtree_folders)
  end

  def scoped_notes_folder(id)
    Current.user.folders.where(id: notes_folder_ids).find(id)
  end

  def scoped_note_file(id)
    notes_files_scope.find(id)
  end

  def resolve_notes_folder(folder_id)
    return notes_root_folder if folder_id.blank?

    scoped_notes_folder(folder_id)
  end

  def notes_folder_tree
    notes_subtree_folders.group_by(&:parent_id)
  end

  def relative_notes_breadcrumb(folder)
    notes_breadcrumb(folder, notes_root_folder)
  end
end

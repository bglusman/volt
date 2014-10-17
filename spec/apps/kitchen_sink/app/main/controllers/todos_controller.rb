class TodosController < ModelController
  model :page

  def add_todo
    self._todos << {name: self._new_todo}
    self._new_todo = ''
  end

  def remove_todo(todo)
    self._todos.delete(todo)
  end

end
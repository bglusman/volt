require 'spec_helper'


class TestUserTodo < Volt::Model
  own_by_user

  permissions(:update) do
    deny :user_id
  end
end

class TestUserTodoWithCrudStates < Volt::Model
  permissions(:create, :update) do |state|
    # Name is set on create, then can not be changed
    deny unless state == :create
  end
end

class ::TestDenyDelete < Volt::Model
  permissions(:delete) do
    deny
  end
end

class ::TestDenyReadName < Volt::Model
  permissions(:read) do
    deny :name
  end
end

class ::TestUpdateReadCheck < Volt::Model
  attr_accessor :create_check, :update_check, :read_check

  permissions(:create) do
    self.create_check = true
    allow
  end

  permissions(:update) do
    self.update_check = true
    allow
  end

  permissions(:read) do
    self.read_check = true
    allow
  end
end

describe "model permissions" do
  it 'should follow CRUD states when checking permissions' do
    todo = TestUserTodoWithCrudStates.new.buffer

    spec_err = nil

    todo._name = 'Test Todo'
    todo.save!.then do
      # Don't allow it to change
      todo._name = 'Jimmy'

      todo.save!.then do
        spec_err = "should not have saved"
      end.fail do |err|
        expect(err).to eq({:name=>["can not be changed"]})
      end
    end.fail do |err|
      spec_err = "Did not save because: #{err.inspect}"
    end

    if spec_err
      fail spec_err
    end
  end

  # it 'should deny an insert/create if a deny without fields' do
  #   store._todos << {name: 'Ryan'}
  # end


  if RUBY_PLATFORM != 'opal'
    describe "read permissions" do
      it 'should deny read on a field' do
        model = store._test_deny_read_names!.buffer
        model._name = 'Jimmy'
        model._other = 'should be visible'

        model.save!.sync

        # Clear the identity map, so we can load up a fresh copy
        model.save_to.persistor.clear_identity_map

        reloaded = store._test_deny_read_names.fetch_first.sync

        expect(reloaded._name).to eq(nil)
        expect(reloaded._other).to eq('should be visible')
      end
    end

    it 'should prevent delete if denied' do
      model = store._test_deny_deletes!.buffer

      model.save!.then do
        # Saved
        count = 0

        store._test_deny_deletes.delete(model).then do
          # deleted
          count += 1
        end

        expect(count).to eq(1)
      end
    end

    it 'should not check the read permissions when updating (so that all fields are present for the permissions check)' do
      model = store._test_update_read_checks!.append({name: 'Ryan'}).sync

      expect(model.create_check).to eq(true)
      expect(model.read_check).to eq(nil)

      # Update
      model._name = 'Jimmy'

      expect(model.read_check).to eq(nil)
      expect(model.update_check).to eq(true)
    end

    it 'should not check read permissions on buffer save on server' do
      model = store._test_update_read_checks!.buffer

      model._name = 'Ryan'

      # Create
      model.save!

      # Create happens on the save_to, not the buffer
      expect(model.save_to.create_check).to eq(true)
      expect(model.save_to.read_check).to eq(nil)

      # Update
      model._name = 'Jimmy'
      model.save!

      expect(model.save_to.read_check).to eq(nil)
      expect(model.save_to.update_check).to eq(true)
    end

    it 'should not check read on delete, so all fields are available to the permissions block' do
      model = store._test_update_read_checks!.append({name: 'Ryan'}).sync

      expect(model.read_check).to eq(nil)

      model.destroy

      expect(model.read_check).to eq(nil)
    end
  end
end
module Api::V1
  class UnclaimedUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false

    property :email,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: true,
               description: "Email address to search by or assign to newly created user"
             }

    property :username,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: true,
               description: "Username to search by or assign to newly created user"
             }

    property :password,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: true,
               description: "Password to set for user, username must also be given"
             }

    property :password_confirmation,
             type: String,
             readable: false,
             writeable: true,
             schema_info: {
               required: true,
               description: "Password to set for user, must match 'password'"
             }
  end
end

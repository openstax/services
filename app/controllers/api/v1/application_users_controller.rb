class Api::V1::ApplicationUsersController < OpenStax::Api::V1::ApiController
  #before_filter :get_app_user, :only => [:show, :update, :destroy]
  
  resource_description do
    api_versions "v1"
    short_description 'Records which users interact with which applications, as well the users'' preferences for each app.'
    description <<-EOS
      All actions in this controller operate only on ApplicationUsers that
      belong to the current application, as determined from the Oauth token.

      ApplicationUser records which users have registered for which OpenStax Accounts applications.
      This information is used to filter search results and control application access to user information.

      User preferences for each app that are used by Accounts are also recorded in ApplicationUser.
      Current preferences include default_contact_info_id, the id of the user's default
      contact info object to be used for each particular application.'
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/application_users',
            'Returns a set of ApplicationUsers matching query terms'
  description <<-EOS
    Accepts a query string along with options and returns a JSON representation
    of the matching ApplicationUsers.  Some User data may be filtered out depending on the
    caller's status and priviledges in the system. The schema for the returned
    JSON result is shown below.

    #{json_schema(Api::V1::ApplicationUserSearchRepresenter, include: :readable)}
  EOS
  # Using route helpers doesn't work in test or production, probably has to do with initialization order
  example "#{api_example(url_base: 'https://accounts.openstax.org/api/application_users', url_end: '?q=username:bob%20name=Jones')}"
  param :q, String, required: true, desc: <<-EOS
    The search query string, built up as a space-separated collection of
    search conditions on different fields.  Each condition is formatted as
    "field_name:comma-separated-values".  The resulting list of ApplicationUsers will
    have Users that match all of the conditions (boolean 'and').  Each condition will produce
    a list of ApplicationUsers whose Users must match any of the comma-separated-values
    (boolean 'or').  The fields_names and their characteristics are given below.
    When a field is listed as using wildcard matching, it means that any fields
    that start with a comma-separated-value will be matched.

    * `username` &ndash; Matches Users' usernames.  Any characters matching
                 `#{ERB::Util.html_escape (User::USERNAME_DISCARDED_CHAR_REGEX.inspect)}`
                 will be discarded. (uses wildcard matching)
    * `first_name` &ndash; Matches Users' first names, case insensitive. (uses wildcard matching)
    * `last_name` &ndash; Matches Users' last names, case insensitive. (uses wildcard matching)
    * `name` &ndash; Matches Users' first, last, or full names, case insensitive. (uses wildcard matching)
    * `id` &ndash; Matches Users' IDs exactly.
    * `email` &ndash; Matches Users' emails exactly.

    You can also add search terms without prefixes, separated by spaces.  These terms  will be searched for
    in all of the prefix categories.  Any ApplicationUsers with matching Users will be returned.
    When combined with prefixed search terms, the final results will contain Users matching any of
    the non-prefixed terms and all of the prefixed terms.

    Examples:

    `username:ric` &ndash; returns ApplicationUsers for 'richb' and 'ricardo' Users.

    `username:ric name:"Van Buren"` &ndash; returns the ApplicationUsers for the 'Ricardo Van Buren' User.

    `ric` &ndash; returns ApplicationUsers for 'richb', 'ricardo', and 'Jimmy Rich' Users.
  EOS
  param :page, Integer, desc: <<-EOS
    Specifies the page of results to retrieve, zero-indexed. (default: 0)
  EOS
  param :per_page, Integer, desc: <<-EOS
    The number of ApplicationUsers to retrieve on the chosen page. (default: 20)
  EOS
  param :order_by, String, desc: <<-EOS
    A string that indicates how to sort the results of the query. The string
    is a comma-separated list of fields with an optional sort direction. The
    sort will be performed in the order the fields are given.
    The fields can be one of #{Api::V1::SearchApplicationUsers::SORTABLE_FIELDS.collect{|sf| "`"+sf+"`"}.join(', ')}.
    Sort directions can either be `ASC` for an ascending sort, or `DESC` for a
    descending sort. If not provided, an ascending sort is assumed. Sort directions
    should be separated from the fields by a space. (default: `username ASC`)

    Example:

    `last_name, username DESC` &ndash; sorts by last name ascending, then by username descending 
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_user, ApplicationUser)
    options = params.slice(:page, :per_page, :order_by)
    outputs = SearchApplicationUsers.call(current_user.application, params[:q], options).outputs
    respond_with outputs, represent_with: Api::V1::ApplicationUserSearchRepresenter
  end

  ###############################################################
  # show
  ###############################################################

#api :GET, '/application_user', 'Gets the ApplicationUser for the current user and current app.'
#description <<-EOS
#  Can only be called by an application using an access token for a user.
#  Gets the ApplicationUser for the current user and current app.

#  #{json_schema(Api::V1::ApplicationUserRepresenter, include: :readable)}
#EOS
#def show
#  standard_read(ApplicationUser, app_user.id)
#end

  ###############################################################
  # update
  ###############################################################

#api :PUT, '/application_user', 'Updates the ApplicationUser for the current user and current app.'
#description <<-EOS
#  Can only be called by an application using an access token for a user.
#  Updates the ApplicationUser for the current user and current app.

#  #{json_schema(Api::V1::ApplicationUserRepresenter, include: [:writeable])}
#EOS
#def update
#  standard_update(ApplicationUser, app_user.id)
#end

  ###############################################################
  # destroy
  ###############################################################

#api :DELETE, '/application_user', 'Deletes the ApplicationUser for the current user and current app.'
#description <<-EOS
#  Can only be called by an application using an access token for a user.
#  Deletes the ApplicationUser for the current user and current app.
#EOS
#def destroy
#  standard_destroy(ApplicationUser, app_user.id)
#end

  ###############################################################
  # updates
  ###############################################################

  api :GET, '/application_users/updates',
            'Gets all ApplicationUsers with unread updates for the current app.'
  description <<-EOS
    Can only be called by an application through the client credentials flow.
    Returns all ApplicationUsers for the current application that have unread updates.

    #{json_schema(Api::V1::ApplicationUsersRepresenter, include: :readable)}
  EOS
  def updates
    OSU::AccessPolicy.require_action_allowed!(:updates, current_user, ApplicationUser)
    outputs = GetUpdatedApplicationUsers.call(current_user.application).outputs
    respond_with outputs[:application_users], represent_with: Api::V1::ApplicationUsersRepresenter
  end

  ###############################################################
  # updated
  ###############################################################

  api :PUT, '/application_users/updated',
            'Marks ApplicationUser updates as "read"'
  description <<-EOS
    Can only be called by an application through the client credentials flow.
    Marks ApplicationUser updates as read for the current application.

    * `application_users` &ndash; Hash containing info about the ApplicationUsers whose updates were read.
                          Keys are ApplicationUser ID's. Values are integers, containing the value of
                          "unread_updates" that you last received for each specific ApplicationUser.

    Examples:

    Assume your app called `updates` and got an ApplicationUser with id: 42 and unread_updates: 2

    `application_users = {42: 2}` &ndash; this is the correct call to `updated`, and marks the
                                  ApplicationUser updates as `read` by setting unread_updates to 0.

    Assume your app called `updates` and got an ApplicationUser with id: 13 and unread_updates: 1

    After you called the API and received your response, the user updated their profile in Accounts,
    setting unread_updates to 2.

    `application_users = {13: 1}` &ndash; will decrease unread_updates by 1, setting it to 1.
                                  The user will be sent again the next time you call `updates`,
                                  so you won't miss the updated information.
  EOS
  def updated
    OSU::AccessPolicy.require_action_allowed!(:updated, current_user, ApplicationUser)
    errors = MarkApplicationUsersUpdatesAsRead.call(current_user.application,
                                                    params[:application_users]).errors
    head (errors.any? ? :internal_server_error : :no_content)
  end

  protected

  def get_app_user
    @app_user = current_user.human_user.application_users.where(
                  :application_id => current_user.application.id
                ).first
  end

end

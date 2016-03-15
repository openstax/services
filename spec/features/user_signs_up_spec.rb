require 'rails_helper'

feature 'User signs up as a local user', js: true do
  scenario 'success' do
    create_application
    visit_authorize_uri

    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Continue'
    expect(page).to have_content('Welcome, testuser')

    click_link 'Continue'
    expect(page).to have_content('Complete your profile information to create your account')

    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).to have_content("First name can't be blank")
    expect(page).to have_content("Last name can't be blank")

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page.current_url).to match(app_callback_url)

    visit '/'
    click_link 'Sign out'
    expect(page).to have_content('Signed out!')
    expect(page).not_to have_content('Welcome, testuser')
    expect(page).to have_content('Sign in with your one OpenStax account!')
  end

  scenario 'with incorrect password confirmation', js: true do
    visit '/'
    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'pass'
    click_button 'Continue'
    expect(page).to have_content("Password doesn't match confirmation")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with empty username', js: true do
    visit '/'
    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: ''
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Continue'
    expect(page).to have_content("Alert: Username can't be blank")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with empty password', js: true do
    visit '/'
    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: ''
    fill_in 'Password Again', with: ''
    click_button 'Continue'
    expect(page).to have_content("Password can't be blank")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with short password', js: true do
    visit '/'
    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'pass'
    fill_in 'Password Again', with: 'pass'
    click_button 'Continue'
    expect(page).to have_content("Password is too short (minimum is 8 characters)")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with a username already taken' do
    create_user 'testuser'
    visit '/'
    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Continue'
    expect(page).to have_content('Username has already been taken', count: 1)
  end

  scenario 'with empty email address', js: true do
    visit '/'
    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: ''
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Continue'
    expect(page).to have_content("Email can't be blank")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with an invalid email address' do
    visit '/'
    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@ex ample.org'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Continue'
    expect(page).to have_content('Value "testuser@ex ample.org" is not a valid email address')
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'without any email addresses' do
    # this is a test for twitter users who have no email addresses
    create_application
    user = create_user 'user'
    # set the user state to "temp" so we can test registration
    user.state = 'temp'
    user.save!

    visit_authorize_uri
    expect(page).to have_content('Sign in with your one OpenStax account!')

    fill_in 'Username', with: 'user'
    fill_in 'Password', with: 'password'
    click_button 'Sign in'

    expect(page).to have_content('Merge Logins')
    click_on 'Continue'

    expect(page).to have_content('Complete your profile information')
    fill_in 'First Name', with: 'First'
    fill_in 'Last Name', with: 'Last'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page.current_url).to match(app_callback_url)
  end
end

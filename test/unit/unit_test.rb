require 'test_helper'

class UnitTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures = true
  fixtures :users
  
  test "authentication" do
    # username with a valid user 
    assert_equal @bob, User.authenticate("bob", "test")    
    
    # username with an invalid username
    assert_nil User.authenticate("nonbob", "test")
    
    # username with an invalid password
    assert_nil User.authenticate("bob", "wrongpass")
    
    # username with an invalid username and password
    assert_nil User.authenticate("nonbob", "wrongpass")
  end
  
  test "password change" do
    # Check username
    assert_equal @longbob, User.authenticate("longbob", "longtest")
    
    # Change password
    @longbob.password = @longbob.password_confirmation = "nonbobpasswd"
    assert @longbob.save
    
    # New password works
    assert_equal @longbob, User.authenticate("longbob", "nonbobpasswd")
    
    # Old password doesn't work anymore
    assert_nil User.authenticate("longbob", "longtest")

    # Change back again
    @longbob.password = @longbob.password_confirmation = "longtest"
    assert @longbob.save
    assert_equal @longbob, User.authenticate("longbob", "longtest")
    assert_nil User.authenticate("longbob", "nonbobpasswd")
  end
  
  test "invalid passwords" do
    # Check that we can't create a user with any of the invalid paswords
    u = User.new    
    u.username = "nonbob"
    u.email = "nonbob@mcbob.com"

    # Too short
    u.password = u.password_confirmation = "tiny" 
    assert ! u.save     
    assert u.errors.invalid?('password')
    
    # Too long
    u.password = u.password_confirmation = "hugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge"
    assert !u.save     
    assert u.errors.invalid?('password')
    
    # Empty
    u.password = u.password_confirmation = ""
    assert !u.save    
    assert u.errors.invalid?('password')
    
    # OK
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save     
    assert u.errors.empty?
  end
  
  test "invalid usernames" do
    # Check that we can't create a user with an invalid username
    u = User.new
    u.password = u.password_confirmation = "bobs_secure_password"
    u.email = "okbob@mcbob.com"
    
    # Too short
    u.username = "x"
    assert !u.save     
    assert u.errors.invalid?('username')
    
    # Too long
    u.username = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhug"
    assert !u.save     
    assert u.errors.invalid?('username')
    
    # Empty
    u.username = ""
    assert !u.save
    assert u.errors.invalid?('username')
    
    # OK
    u.username = "okbob"
    assert u.save  
    assert u.errors.empty?
    
    # No email
    u.email=nil   
    assert !u.save     
    assert u.errors.invalid?('email')
    
    # Invalid email
    u.email='notavalidemail'   
    assert !u.save     
    assert u.errors.invalid?('email')
    
    # OK
    u.email="validbob@mcbob.com"
    assert u.save  
    assert u.errors.empty?
  end
  
  test "name collision" do
    # Check can't create new user with existing username
    u = User.new
    u.username = "existingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert !u.save
  end
  
  test "create" do
    # Check create works
    u = User.new
    u.username      = "nonexistingbob"
    u.password = u.password_confirmation = "bobs_secure_password"
    u.email="nonexistingbob@mcbob.com"  
    assert_not_nil u.salt
    assert u.save
    assert_equal 10, u.salt.length
    
    # Check username works
    assert_equal u, User.authenticate(u.username, u.password)

    # Check create works again
    u = User.new(:username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", :email => "newbob@mcbob.com" )
    assert_not_nil u.salt
    assert_not_nil u.password
    assert_not_nil u.hashed_password
    assert u.save
    
    # Check username works again
    assert_equal u, User.authenticate(u.username, u.password)
  end
  
  test "random string" do
    new_pass = User.random_string(10)
    assert_not_nil new_pass
    assert_equal 10, new_pass.length
  end
  
  test "SHA1" do
    u=User.new
    u.username = "nonexistingbob"
    u.email = "nonexistingbob@mcbob.com"  
    u.salt = "1000"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save   
    assert_equal 'b1d27036d59f9499d403f90e0bcf43281adaa844', u.hashed_password
    assert_equal 'b1d27036d59f9499d403f90e0bcf43281adaa844', User.encrypt("bobs_secure_password", "1000")
  end
  
  test "protected attributes" do
    # Check attributes are protected
    u = User.new(:id=>999999, :salt=>"I-want-to-set-my-salt", :username => "badbob", :password => "newpassword", :password_confirmation => "newpassword", :email => "badbob@mcbob.com" )
    assert u.save
    assert_not_equal 999999, u.id
    assert_not_equal "I-want-to-set-my-salt", u.salt

    u.update_attributes(:id=>999999, :salt=>"I-want-to-set-my-salt", :username => "verybadbob")
    assert u.save
    assert_not_equal 999999, u.id
    assert_not_equal "I-want-to-set-my-salt", u.salt
    assert_equal "verybadbob", u.username
  end
end


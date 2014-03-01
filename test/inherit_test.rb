
  class NestedInheritanceTest < MiniTest::Spec
    class UserDecorator < Representable::Decorator
      include Representable::Hash
      property :contact do
        property :first_name
        property :last_name
      end
    end

    class CompanyDecorator < UserDecorator
      property :contact, :inherit => true do
        property :fax_number
      end
    end

    let (:user) do
      OpenStruct.new({
        :contact => OpenStruct.new(
          :first_name => "Jane"
        )
      })
    end

    let (:user_decorator) do
      UserDecorator.new(user)
    end

    let (:company_decorator) do
      CompanyDecorator.new(user)
    end

    it "should inherit nested properties" do
      company_contact = company_decorator.send(:representable_attrs)['contact'].representer_module
      company_contact.send(:representable_attrs).keys.must_include 'first_name'
    end

    it "should not interfere with superclass attributes" do
      user_contact = user_decorator.send(:representable_attrs)['contact'].representer_module
      user_contact.send(:representable_attrs).keys.wont_include 'fax_number'
    end
  end
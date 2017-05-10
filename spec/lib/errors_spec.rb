require 'spec_helper'
require 'errors'

describe "internal_error" do
	it "should raise InternalError" do
		expect{ internal_error("foo") }.to raise_error(InternalError)
	end
end

describe "no_such_resource" do
	it "should raise NoSuchResourceError" do
		expect{ no_such_resource("foo") }.to raise_error(NoSuchResourceError)
	end
end

describe "unauthorized" do
	it "should raise AuthenticationError" do
		expect{ unauthorized }.to raise_error(AuthenticationError)
	end
end

describe "forbidden" do
	it "should raise AuthorizationError" do
		expect{ forbidden }.to raise_error(AuthorizationError)
	end
end

describe "conflicted_resource" do
	it "should raise ConflictedResourceError" do
		expect{ conflicted_resource("foo") }.to raise_error(ConflictedResourceError)
	end
end

describe "too_many_requests" do
	it "should raise TooManyRequestsError" do
		expect{ too_many_requests("foo") }.to raise_error(TooManyRequestsError)
	end
end

describe "invalid_token" do
	it "should raise TokenError" do
		expect{ invalid_token }.to raise_error(TokenError)
	end
end

describe "not_implemented" do
	it "should raise NotImplementedError" do
		expect{ not_implemented }.to raise_error(NotImplementedError)
	end
end

describe "missing_argument" do
	it "should raise ArgumentError" do
		expect{ missing_argument("foo") }.to raise_error(ArgumentError)
	end
end

describe "invalid_argument" do
	it "should raise ArgumentError" do
		expect{ invalid_argument("foo", "bar") }.to raise_error(ArgumentError)
	end
end

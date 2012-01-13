module FakeBraintree
  class Subscription
    include Helpers

    def initialize(subscription_hash, options)
      @subscription_hash = subscription_hash.merge("merchant_id" => options[:merchant_id],
                                                   "id" => options[:id])
    end

    def create
      hash = subscription_hash
      FakeBraintree.registry.subscriptions[hash["id"]] = hash
      gzipped_response(201, hash.to_xml(:root => 'subscription'))
    end

    def update
      if subscription_exists_in_registry?
        updated_subscription = update_subscription!(subscription_hash)
        response_for_created_subscription(updated_subscription)
      else
        response_for_subscription_not_found
      end
    end

    def subscription_hash
      subscription_hash = @subscription_hash.dup
      subscription_hash["id"]                   ||= generate_new_subscription_id
      subscription_hash["transactions"]         = []
      subscription_hash["add_ons"]              = added_add_ons
      subscription_hash["discounts"]            = added_discounts
      subscription_hash["plan_id"]              = plan_id
      subscription_hash["next_billing_date"]    = braintree_formatted_date(1.month.from_now)
      subscription_hash["payment_method_token"] = payment_method_token
      subscription_hash["status"]               ||= active_status

      subscription_hash
    end

    private

    def update_subscription!(updates)
      updated_subscription = subscription_from_registry.merge(updates)
      FakeBraintree.registry.subscriptions[subscription_id] = updated_subscription
    end

    def subscription_from_registry
      FakeBraintree.registry.subscriptions[subscription_id]
    end

    def subscription_exists_in_registry?
      FakeBraintree.registry.subscriptions.key?(subscription_id)
    end

    def braintree_formatted_date(date)
      date.strftime('%Y-%m-%d')
    end

    def added_add_ons
      if @subscription_hash["add_ons"] && @subscription_hash["add_ons"]["add"]
        @subscription_hash["add_ons"]["add"].map { |add_on| { "id" => add_on["inherited_from_id"] } }
      else
        []
      end
    end

    def added_discounts
      if @subscription_hash["discounts"] && @subscription_hash["discounts"]["add"]
        @subscription_hash["discounts"]["add"].map { |discount| { "id" => discount["inherited_from_id"] } }
      else
        []
      end
    end

    def subscription_id
      @subscription_hash["id"]
    end

    def plan_id
      @subscription_hash["plan_id"]
    end

    def payment_method_token
      @subscription_hash["payment_method_token"]
    end

    def generate_new_subscription_id
      md5("#{@subscription_hash["payment_method_token"]}#{Time.now.to_f}")[0,6]
    end

    def active_status
      Braintree::Subscription::Status::Active
    end

    def response_for_subscription_not_found
      gzipped_response(404, {})
    end

    def response_for_created_subscription(hash)
      gzipped_response(201, hash.to_xml(:root => "subscription"))
    end
  end
end

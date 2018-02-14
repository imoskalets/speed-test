module Speed
  require 'benchmark'

  class << self

    def insert_test(count = 10)
      Rails.logger.info 'INSERT:'
      policy = policy_data
      Benchmark.bm(5) do |x|
        x.report('MONGO') { count.times { Mongo::Policy.create(data: policy) } }
        x.report('MARIA') { count.times { Policy.create(data: policy) } }
      end
    end

    def update_test(count = 10)
      Rails.logger.info 'UPDATE:'
      offset  = rand(User.count)
      user_id = User.offset(offset).first.id

      Benchmark.bm(5) do |x|
        x.report('MONGO') { count.times {
          policy = Mongo::Policy.where(user_id: user_id).first
          policy.data['coverages']['total_sum'] = rand(1000)
          policy.save
        } }
        x.report('MARIA') { count.times {
          policy = Policy.where(user_id: user_id).first
          policy.data['coverages']['total_sum'] = rand(1000)
          policy.save
        } }
      end
    end

    def update_by_query_test(count = 10)
      Rails.logger.info 'UPDATE BY QUERY:'
      offset  = rand(User.count)
      user_id = User.offset(offset).first.id

      Benchmark.bm(5) do |x|
        x.report('MONGO') { count.times {
          total_sum = rand(1000)
          Mongo::Policy.where(user_id: user_id).update_all('coverages.total_sum' => total_sum)
        } }
        x.report('MARIA') { count.times {
          total_sum = rand(1000)
          Policy.where(user_id: user_id).update_all("data = JSON_REPLACE(data, '$.coverages.total_sum', #{total_sum})")
        } }
      end
    end

    def select_test(count = 10)
      Rails.logger.info 'SELECT:'
      mileage, fuel = 620000, 'Lucky'

      Benchmark.bm(5) do |x|
        x.report('MONGO') { count.times {
          Mongo::Policy.where(:'data.car.mileage'.gte => mileage, 'data.car.fuel' => fuel)
              .each { |p| p.data['coverages']['total_sum'] }
        } }
        x.report('MARIA') { count.times {
          Policy.where("JSON_EXTRACT(data, '$.car.mileage') > ? AND JSON_EXTRACT(data, '$.car.fuel') = ?", mileage, fuel )
              .each {|p| p.data['coverages']['total_sum']}
        } }
      end
    end

    def select_by_index_test(count = 10 )
      Rails.logger.info 'SELECT BY INDEX:'
      offset  = rand(User.count)
      user_id = User.offset(offset).first.id

      Benchmark.bm(5) do |x|
        x.report('MONGO') { count.times { Mongo::Policy.where(user_id: user_id).first } }
        x.report('MARIA') { count.times { Policy.where(user_id: user_id).first } }
      end
    end

    def count_by_index_test(count = 10 )
      Rails.logger.info 'COUNT BY INDEX:'
      offset  = rand(User.count)
      user_id = User.offset(offset).first.id

      Benchmark.bm(5) do |x|
        x.report('MONGO') { count.times { Mongo::Policy.where(user_id: user_id).count } }
        x.report('MARIA') { count.times { Policy.where(user_id: user_id).count } }
      end
    end

    def first_test(count = 10)
      Rails.logger.info 'FIRST:'
      mileage, fuel = 620000, 'Lucky'

      Benchmark.bm(5) do |x|
        x.report('MONGO') { count.times {
          Mongo::Policy.where(:'data.car.mileage'.gte => mileage, 'data.car.fuel' => fuel).first
        } }
        x.report('MARIA') { count.times {
          Policy.where("JSON_EXTRACT(data, '$.car.mileage') > ? AND JSON_EXTRACT(data, '$.car.fuel') = ?", mileage, fuel ).first
        } }
      end
    end

    def count_test(count = 10)
      Rails.logger.info 'COUNT:'
      mileage, fuel = 620000, 'Lucky'

      Benchmark.bm(5) do |x|
        x.report('MONGO') { count.times {
          Mongo::Policy.where(:'data.car.mileage'.gte => mileage, 'data.car.fuel' => fuel).count
        } }
        x.report('MARIA') { count.times {
          Policy.where("JSON_EXTRACT(data, '$.car.mileage') > ? AND JSON_EXTRACT(data, '$.car.fuel') = ?", mileage, fuel ).count
        } }
      end
    end

    def complex
      Rails.logger.info "START: Users: #{User.count}, Mongo: #{Mongo::Policy.count}, Maria: #{Policy.count}"
      [1, 10, 100, 1000].each do|count|
        Rails.logger.info "------------------------#{count}------------------------"
        insert_test(count)
        update_test(count)
        update_by_query_test(count)
        select_test(count)
        select_by_index_test(count)
        first_test(count)
        count_test(count)
        count_by_index_test(count)
      end
      Rails.logger.info "END: Users: #{User.count}, Mongo: #{Mongo::Policy.count}, Maria: #{Policy.count}"
      Rails.logger.info ".........END........."
    end

    def generate_data(users = 10, policies = 10)
      users.times do |_|
        User.transaction do
          user = User.create(name: Faker::Name.name, email: Faker::Internet.email, password: Faker::Internet.password)
          policies.times do |_|
            policy = policy_data
            Policy.create user: user, data: policy
            Mongo::Policy.create user_id: user.id, data: policy
          end
        end
      end
    end

    def policy_data
      {
          "car": {
              "auto_transmission": Faker::Boolean.boolean,
              "body_type": Faker::Name.first_name,
              "brand": Faker::Company.name,
              "category": Faker::Company.suffix,
              "curb_weight_min": Faker::Company.name,
              "dmr_insurance_policy_number": Faker::Number.number(3).to_i,
              "dmr_insurance_start_date": Faker::Date.backward,
              "dmr_insurance_status": Faker::Company.name,
              "dmr_insurance_vendor": Faker::Company.name,
              "dmr_last_update_date": Faker::Date.backward,
              "dmr_last_update_type": Faker::Date.backward,
              "engine_power": Faker::Number.number(3).to_i,
              "engine_size": Faker::Number.number(3).to_i,
              "extras": Faker::Number.number(3).to_i,
              "fuel": Faker::Dog.name,
              "fuel_efficiency": Faker::Number.number(3).to_i,
              "hp": Faker::Number.number(3).to_i,
              "license_plate": Faker::PhoneNumber.phone_number,
              "mileage": Faker::Number.number(6).to_i,
              "model": Faker::Company.name,
              "price": Faker::Number.number(3).to_i,
              "register_date": Faker::Date.backward,
              "total_cylinders": Faker::Number.number(1).to_i,
              "total_doors": Faker::Number.number(1).to_i,
              "total_seats": Faker::Number.number(1).to_i,
              "tow_bar": Faker::Boolean.boolean,
              "typegodkendelse": Faker::Boolean.boolean,
              "usage": Faker::Dog.name,
              "variant": Faker::Dog.breed,
              "vehicle_type": Faker::Dog.name,
              "vin": Faker::PhoneNumber.phone_number,
              "weight": {
                  "net": Faker::Number.number(4).to_i,
              },
              "year": Faker::Date.between(10.years.ago, Date.today).year,
          },
          "coverages": {
              "comprehensive_coverage": {
                  "covered": Faker::Boolean.boolean,
                  "deductible": Faker::Number.number(4).to_i,
                  "name": Faker::Company.catch_phrase
              },
              "fire": {
                  "covered": Faker::Boolean.boolean,
                  "deductible": Faker::Number.number(4).to_i,
                  "name": Faker::Company.catch_phrase
              },
              "liability": {
                  "covered": Faker::Boolean.boolean,
                  "name": Faker::Company.catch_phrase
              },
              "total_deductible": Faker::Number.number(4).to_i,
              "total_sum": Faker::Number.number(4).to_i
          },
          "end_date": Faker::Date.forward(365),
          "insurance_type": nil,
          "leased": Faker::Boolean.boolean,
          "maturity_date": Faker::Date.birthday(18, 65),
          "mileage": Faker::Number.number(2).to_i,
          "policy_holders": [
              {
                  "address": Faker::Address.street_address,
                  "birthdate": Faker::Date.birthday(18, 65),
                  "cpr": Faker::PhoneNumber.phone_number,
                  "name": Faker::Name.name
              },
              {
                  "address": Faker::Address.street_address,
                  "birthdate": Faker::Date.birthday(18, 65),
                  "cpr": Faker::PhoneNumber.phone_number,
                  "name": Faker::Name.name
              }
          ],
          "policy_number": Faker::PhoneNumber.phone_number,
          "policy_type": "car",
          "premium_step": 10,
          "start_date": Faker::Date.backward,
          "terms": [Faker::Dog.coat_length, Faker::Dog.size, Faker::Dog.gender, Faker::Dog.age],
          "update_date": Faker::Date.backward,
          "yearly_price": Faker::Number.number(8)
      }
    end

  end

end

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Winston #{n}" }
    permissions { %w[signin] }

    factory :editor do
      permissions { %w(signin editor) }
    end

    factory :admin do
      permissions { %w(signin editor admin) }
    end
  end

  sequence :content_id do |_|
    SecureRandom.uuid
  end

  factory :need_content_item, class: Hash do
    content_id
    base_path { "/needs/find-out-if-an-estate-is-claimable-and-how-to-make-a-claim-on-an-estate" }
    title { "find out if an estate is claimable and how to make a claim on an estate" }
    description {
      "As a relative of a deceased person, I need to find out if an estate is claimable and how to make a claim on an estate, so that claim my entitlement"
    }
    schema_name { "need" }
    publishing_app { "maslow" }
    rendering_app { "info-frontend" }
    locale { "en" }
    phase { "live" }
    redirects { [] }
    update_type { "major" }
    public_updated_at { "2015-11-16T11:53:30+00:00" }
    updated_at { "2015-11-16T11:53:30+00:00" }
    first_published_at { nil }
    last_edited_at { "2015-11-15T11:53:30" }
    publication_state { "draft" }
    state_history {
      { "1": "draft" }
    }

    user_facing_version { 3 }
    routes {
      [
        {
          "path" => base_path,
          "type" => "exact",
        },
      ]
    }

    details { default_details }

    transient do
      default_details {
        {
          "applies_to_all_organisations": false,
          "benefit": "claim my entitlement",
          "goal": "find out if an estate is claimable and how to make a claim on an estate",
          "justifications": [
            "The government is legally obliged to provide it",
            "It's inherent to a person's or an organisation's rights and obligations",
          ],
          "impact": "Noticed by the average member of the public",
          "met_when": [
                       "Knows how to find the list and claim an estate",
                       "Claims an estate",
                      ],
          "legislation": "Driving Test Act 1994, Schedule 8",
          "yearly_need_views": 824000,
          "yearly_site_views": 2527607,
          "yearly_user_contacts": 8000,
          "yearly_searches": 630000,
          "need_id": 100002,
          "other_evidence": "Relatives are entitled to claim up to 30 years after the death; it is their money to claim and it can only be claimed through the Treasury Solicitor",
          "role": "relative of a deceased person",
        }
      }
      default_metadata { {} }
    end

    initialize_with {
      merged_details = default_details.deep_stringify_keys.deep_merge(details.deep_stringify_keys)
      attributes.merge(details: merged_details)
    }

    # This is the default document state.
    trait :draft do
    end

    to_create(&:deep_stringify_keys!)
  end
end

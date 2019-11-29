# encoding: UTF-8

require_relative "../integration_test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class ViewANeedTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::PublishingApiV2
  include NeedHelper

  setup do
    login_as_stub_user

    @content_item = create(:need_content_item)
    @dvla_content_id = SecureRandom.uuid
    @dsa_content_id = SecureRandom.uuid
    publishing_api_has_linkables([
      {
        "content_id": @dvla_content_id,
        "title" => "Driver and Vehicle Licensing Agency",
      },
      {
        "content_id": @dsa_content_id,
        "title" => "Driving Standards Agency",
      },
    ], document_type: "organisation")
    publishing_api_has_content(
      [@content_item],
      Need.default_options.merge(
        per_page: 50,
      ),
    )
    publishing_api_has_item(@content_item)
    publishing_api_has_linked_items(
      [
        {
          title: "Linked item title",
          base_path: "linked_foo",
          document_type: "guide",
        },
      ],
      content_id: @content_item["content_id"],
      link_type: "meets_user_needs",
      fields: %w[title base_path document_type],
    )
    publishing_api_has_links(
      content_id: @content_item["content_id"],
      links: {
        organisations: [@dvla_content_id, @dsa_content_id],
      },
    )

    Note.create(
      content_id: @content_item["content_id"],
      text: "looks good",
      author: { name: "Testy McTestFace" },
      created_at: Time.zone.local(2017, 1, 5, 13),
    )
  end

  context "given a need which exists" do
    should "show basic information about the need" do
      visit "/needs"
      click_on format_need_goal(@content_item["details"]["goal"])

      within ".breadcrumb" do
        assert page.has_link?("All needs", href: "/needs")
        assert page.has_content?(format_need_goal(@content_item["details"]["goal"]))
      end

      within ".need" do
        within "header" do
          within ".need-organisations" do
            assert page.has_content?(
              "Driver and Vehicle Licensing Agency, Driving Standards Agency",
                   )
          end

          assert page.has_content?("Status: Proposed")
        end

        within ".nav-tabs" do
          assert page.has_link?(
            "History & Notes",
            href: "/needs/#{@content_item['content_id']}/revisions",
          )
        end

        within ".the-need" do
          assert page.has_content?("As a #{@content_item['details']['role']} I need to #{@content_item['details']['goal']} So that #{@content_item['details']['benefit']}")
        end

        within ".met-when" do
          @content_item["details"]["met_when"].each do |content|
            assert page.has_content?(content)
          end
        end

        within ".justifications" do
          @content_item["details"]["justifications"].each do |content|
            assert page.has_content?(content)
          end
        end

        within ".impact" do
          assert page.has_content?("If GOV.UK didn't meet this need it would be noticed by the general public")
        end

        assert page.has_no_content?("This need applies to all organisations.")

        within ".interactions" do
          assert page.has_content?("824k Approximate pageviews a year")
          assert page.has_content?("32.6% of site pageviews")
          assert page.has_content?("8k Approximate contacts a year")
          assert page.has_content?("630k Approximate searches a year")
        end

        within ".legislation" do
          assert page.has_content?("Driving Test Act 1994, Schedule 8")
        end

        within ".other-evidence" do
          assert page.has_content?("Relatives are entitled to claim up to 30 years after the death; it is their money to claim and it can only be claimed through the Treasury Solicitor")
        end
      end
    end

    should "show the recent revisions and notes" do
      visit "/needs"

      click_on format_need_goal(@content_item["details"]["goal"])
      click_on "History & Notes"

      within ".breadcrumb" do
        assert page.has_link?("All needs", href: "/needs")
        assert page.has_content?("History & Notes")
      end

      within ".need" do
        within ".revisions" do
          assert_equal 3, page.all(".revision").count
          assert_equal 1, page.all(".note-history").count

          within ".note-history" do
            assert page.has_content?("looks good")
            assert page.has_content?("Testy McTestFace")
            assert page.has_content?("1:00pm, 5 January 2017")
          end

          within(:xpath, "//*[@id='revision-history']/ul/li[2]") do
            assert page.has_content?("11:53am, 16 November 2015")

            within ".changes" do
              assert page.has_content?("Goal: blank → find out if an estate is claimable and how to make a claim on an estate")
              assert page.has_content?("Role: blank → relative of a deceased person")
            end
          end
        end
      end
    end

    context "showing content which meet the need" do
      should "display content from the publishing api" do
        visit "/needs"
        click_on format_need_goal(@content_item["details"]["goal"])

        within ".need" do
          assert page.has_selector?("table#content-items-meeting-this-need")

          within "table#content-items-meeting-this-need" do
            assert page.has_selector?("tbody tr", count: 1)

            within "tbody" do
              within "tr:first-child" do
                assert page.has_link?(
                  "Linked item title",
                  href: "#{Plek.new.website_root}/linked_foo",
                )
              end
            end
          end
        end
      end

      should "not display a table when there are no content items for this need" do
        publishing_api_has_linked_items(
          [],
          content_id: @content_item["content_id"],
          link_type: "meets_user_needs",
          fields: %w[title base_path document_type],
        )

        visit "/needs"
        click_on format_need_goal(@content_item["details"]["goal"])

        # check the page has loaded correctly
        assert page.has_content?(format_need_goal(@content_item["details"]["goal"]))

        within ".need" do
          assert page.has_no_selector?("table#content-items-meeting-this-need")
        end
      end
    end
  end

  context "given a need with missing attributes" do
    setup do
      @content_item["details"].delete("met_when")
      @content_item["details"].delete("justifications")
      @content_item["details"].delete("impact")
      @content_item["details"].delete("legislation")
      @content_item["details"].delete("other_evidence")

      publishing_api_has_item(@content_item)
    end

    should "show basic information about the need" do
      visit "/needs"
      click_on format_need_goal(@content_item["details"]["goal"])

      within ".need" do
        within "header" do
          assert page.has_content?(format_need_goal(@content_item["details"]["goal"]))
        end

        within ".the-need" do
          role, goal, benefit = @content_item["details"].values_at("role", "goal", "benefit")
          assert page.has_content?("As a #{role} I need to #{goal} So that #{benefit}")
        end

        assert page.has_no_selector?(".met-when")
        assert page.has_no_selector?(".justifications")
        assert page.has_no_selector?(".impact")
        assert page.has_no_selector?(".legislation")
        assert page.has_no_selector?(".other-evidence")
      end
    end
  end

  context "given a need which applies to all organisations" do
    setup do
      @content_item["details"]["applies_to_all_organisations"] = true
      publishing_api_has_item(@content_item)
      publishing_api_has_links(
        content_id: @content_item["content_id"],
        links: {
          organisations: [],
        },
      )
    end

    should "show basic information about the need" do
      visit "/needs"
      click_on format_need_goal(@content_item["details"]["goal"])

      within ".need" do
        within "header" do
          assert page.has_no_selector?(".need-organisations")

          assert page.has_content?(format_need_goal(@content_item["details"]["goal"]))
        end

        within ".the-need" do
          role, goal, benefit = @content_item["details"].values_at("role", "goal", "benefit")
          assert page.has_content?("As a #{role} I need to #{goal} So that #{benefit}")
        end

        assert page.has_content?("This need applies to all organisations.")
      end
    end
  end

  context "given a need which is not valid" do
    setup do
      @content_item["publication_state"] = "unpublished"
      @content_item["unpublishing"] = {
        "type" => "withdrawal",
        "explanation" => "This need is not valid because: x",
      }

      publishing_api_has_item(@content_item)
    end

    should "indicate that it is not valid" do
      visit "/needs"
      click_on format_need_goal(@content_item["details"]["goal"])

      assert page.has_content?("This need is not valid because:")
    end
  end

  context "given a need which doesn't exist" do
    content_id = SecureRandom.uuid

    setup do
      publishing_api_does_not_have_item(content_id)
    end

    should "display a not found error message" do
      visit "/needs/#{content_id}"

      assert page.has_content?("The page you were looking for doesn't exist.")
    end
  end
end

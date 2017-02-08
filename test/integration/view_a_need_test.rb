# encoding: UTF-8
require_relative '../integration_test_helper'
require 'gds_api/test_helpers/publishing_api_v2'

class ViewANeedTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::PublishingApiV2
  include NeedHelper

  setup do
    login_as_stub_user

    @content_item = create(:need_content_item)
    publishing_api_has_linkables([], document_type: "organisation")
    publishing_api_has_content(
      [@content_item],
      Need.default_options.merge(
        per_page: 50
      )
    )
    publishing_api_has_item(@content_item)
    publishing_api_has_linked_items(
      [],
      content_id: @content_item["content_id"],
      link_type: "meets_user_needs",
      fields: ["title", "base_path", "document_type"]
    )
    publishing_api_has_links(
      content_id: @content_item["content_id"],
      links: {
        organisations: []
      }
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
            assert page.has_content?("Driver and Vehicle Licensing Agency, Driving Standards Agency")
            assert page.has_link?("Driver and Vehicle Licensing Agency",
                                  href: needs_url(organisation_id: "driver-vehicle-licencing-agency"))
            assert page.has_link?("Driving Standards Agency",
                                  href: needs_url(organisation_id: "driving-standards-agency"))
          end

          assert page.has_content?("Book a driving test")

          assert page.has_content?("Status: proposed")
        end

        within ".nav-tabs" do
          assert page.has_link?("History & Notes", href: "/needs/101350/revisions")
        end

        within ".the-need" do
          assert page.has_content?("As a user \nI need to book a driving test \nSo that I can get my driving licence")
        end

        within ".met-when" do
          assert page.has_content?("Users can book their driving test")
          assert page.has_content?("Users can find out information about the format of the test and how much it costs")
        end

        within ".justifications" do
          assert page.has_content?("It's something only government does")
          assert page.has_content?("It's straightforward advice that helps people to comply with their statutory obligations")
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
          assert page.has_content?("Primary service provided by the DVLA")
        end
      end
    end

    should "show the recent revisions and notes" do
      visit "/needs"

      click_on format_need_goal(@content_item["details"]["goal"])
      click_on "History & Notes"

      within ".breadcrumb" do
        assert page.has_link?("All needs", href: "/needs")
        assert page.has_link?("101350: Book a driving test", href: "/needs/101350")
        assert page.has_content?("History & Notes")
      end

      within ".need" do
        within "header" do
          within ".need-organisations" do
            assert page.has_content?("Driver and Vehicle Licensing Agency, Driving Standards Agency")
            assert page.has_link?("Driver and Vehicle Licensing Agency",
                                  href: needs_url(organisation_id: "driver-vehicle-licencing-agency"))
            assert page.has_link?("Driving Standards Agency",
                                  href: needs_url(organisation_id: "driving-standards-agency"))
          end

          assert page.has_content?("Book a driving test")
        end

        within ".nav-tabs" do
          assert page.has_no_link?("See history")
        end

        within ".revisions" do
          assert_equal 3, page.all(".revision").count
          assert_equal 1, page.all(".note-history").count

          within ".note-history" do
            assert page.has_content?("looks good")
            assert page.has_content?("Testy McTestFace")
            assert page.has_content?("1:00pm, 5 January 2017")
          end

          within(:xpath, "//*[@id='revision-history']/ul/li[2]") do
            assert page.has_content?("Update by Mickey Mouse <mickey.mouse@test.com>")
            assert page.has_content?("2:00pm, 1 May 2013")

            within ".changes" do
              assert_equal 2, page.all("li").count

              assert page.has_content?("Goal: apply for a secondary school place → apply for a primary school place")
              assert page.has_content?("Role: blank → parent")
            end
          end

          within(:xpath, "//*[@id='revision-history']/ul/li[3]") do
            assert page.has_content?("Update by unknown author")
            assert page.has_no_content?("<>") # catch missing email
            assert page.has_content?("2:00pm, 1 April 2013")
          end

          within(:xpath, "//*[@id='revision-history']/ul/li[4]") do
            assert page.has_content?("Create by Donald Duck")
            assert page.has_no_content?("<>") # catch an empty email string
            assert page.has_content?("1:00pm, 1 January 2013")

            within ".changes" do
              assert_equal 2, page.all("li").count

              assert page.has_content?("Goal: apply for a school place → apply for a secondary school place")
              assert page.has_content?("Role: grandparent → blank")
            end
          end
        end
      end
    end # should show recent revisions

    context "showing content which meet the need" do
      setup do
        linked_content_items = create_list(:need_content_item, 2)
        publishing_api_has_linked_items(
          linked_content_items,
          content_id: @content_item["content_id"],
          link_type: "meets_user_needs"
        )
      end

      should "display content from the publishing api" do
        visit "/needs"
        click_on format_need_goal(@content_item["details"]["goal"])

        within ".need" do
          assert page.has_selector?("table#content-items-meeting-this-need")

          within "table#content-items-meeting-this-need" do
            assert page.has_selector?("tbody tr", count: 2)

            within "tbody" do
              within "tr:first-child" do
                assert page.has_link?("VAT rates", href: "http://www.dev.gov.uk/vat-rates")
                assert page.has_content?("Answer")
              end

              within "tr:nth-child(2)" do
                assert page.has_link?("VAT", href: "http://www.dev.gov.uk/vat")
                assert page.has_content?("Business support")
              end
            end # within tbody
          end # within table
        end # within .need
      end # should display artefacts from the content api

      should "not display a table when there are no content items for this need" do
        linked_content_items = create_list(:need_content_item, 2)
        publishing_api_has_linked_items(
          linked_content_items,
          content_id: @content_item["content_id"],
          link_type: "meets_user_needs"
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
    should "show basic information about the need" do
      visit "/needs"
      click_on format_need_goal(@content_item["details"]["goal"])

      within ".need" do
        within "header" do
          assert page.has_no_selector?(".need-organisations")

          assert page.has_content?(format_need_goal(@content_item["details"]["goal"]))
        end

        within ".the-need" do
          role, goal, benefit = @content_item["details"].slice("role", "goal", "benefit")
          assert page.has_content?(
                   "As a #{role}\nI need to #{goal}\nSo that #{benefit}"
                 )
        end

        assert page.has_no_selector?(".met-when")
        assert page.has_no_selector?(".justifications")
        assert page.has_no_selector?(".impact")
        assert page.has_no_selector?(".interactions")
        assert page.has_no_selector?(".legislation")
        assert page.has_no_selector?(".other-evidence")
      end
    end
  end

  context "given a need which applies to all organisations" do
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
          assert page.has_content?(
                   "As a #{role}\nI need to #{goal}\nSo that #{benefit}"
                 )
        end

        assert page.has_content?("This need applies to all organisations.")
      end
    end
  end

  context "given a need which is not valid" do
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

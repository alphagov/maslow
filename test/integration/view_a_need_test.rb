# encoding: UTF-8
require_relative '../integration_test_helper'

class ViewANeedTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
    need_api_has_organisations(
      "driver-vehicle-licensing-agency" => "Driver and Vehicle Licensing Agency",
      "driving-standards-agency" => "Driving Standards Agency",
    )
  end

  context "given a need which exists" do
    setup do
      setup_need_api_responses(101350)
    end

    should "show basic information about the need" do
      visit "/needs"
      click_on "101350"

      within ".breadcrumb" do
        assert page.has_link?("All needs", href: "/needs")
        assert page.has_content?("101350: Book a driving test")
      end

      within ".need" do
        within "header" do
          within ".need-organisations" do
            assert page.has_content?("Driver and Vehicle Licensing Agency, Driving Standards Agency")
          end

          assert page.has_content?("Book a driving test")
          assert page.has_link?("Edit need", href: "/needs/101350/edit")
          assert page.has_link?("See history", href: "/needs/101350/revisions")
        end

        within ".the-need" do
          assert page.has_content?("As a user \nI need to book a driving test \nSo that I can get my driving licence")
        end

        assert page.has_button?("Mark as out of scope")

        within ".met-when" do
          assert page.has_content?("Users can book their driving test")
          assert page.has_content?("Users can find out information about the format of the test and how much it costs")
        end

        within ".justifications" do
          assert page.has_content?("It's something only government does")
          assert page.has_content?("It's straightforward advice that helps people to comply with their statutory obligations")
        end

        within ".impact" do
          assert page.has_content?("If GOV.UK didn't meet this need it would be noticed by the average member of the public")
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

    should "show the recent revisions" do
      visit "/needs"

      click_on "101350"
      click_on "See history"

      within ".breadcrumb" do
        assert page.has_link?("All needs", href: "/needs")
        assert page.has_link?("101350: Book a driving test", href: "/needs/101350")
        assert page.has_content?("History")
      end

      within ".need" do
        within "header" do
          within ".need-organisations" do
            assert page.has_content?("Driver and Vehicle Licensing Agency, Driving Standards Agency")
          end

          assert page.has_content?("Book a driving test")
          assert page.has_link?("Edit need", href: "/needs/101350/edit")
          assert page.has_no_link?("See history")
        end

        within ".revisions" do
          assert_equal 3, page.all(".revision").count

          within ".revision:nth-child(1)" do
            assert page.has_content?("Update by Mickey Mouse <mickey.mouse@test.com>")
            assert page.has_content?("1 May 2013, 13:00")

            within ".changes" do
              assert_equal 2, page.all("li").count

              assert page.has_content?("Goal: apply for a secondary school place → apply for a primary school place")
              assert page.has_content?("Role: blank → parent")
            end
          end

          within ".revision:nth-child(2)" do
            assert page.has_content?("Update by unknown author")
            assert page.has_no_content?("<>") # catch missing email
            assert page.has_content?("1 April 2013, 13:00")
          end

          within ".revision:nth-child(3)" do
            assert page.has_content?("Create by Donald Duck")
            assert page.has_no_content?("<>") # catch an empty email string
            assert page.has_content?("1 January 2013, 13:00")

            within ".changes" do
              assert_equal 2, page.all("li").count

              assert page.has_content?("Goal: apply for a school place → apply for a secondary school place")
              assert page.has_content?("Role: grandparent → blank")
            end
          end
        end
      end
    end # should show recent revisions

    context "showing artefacts which meet the need" do
      should "display artefacts from the content api" do
        content_api_has_artefacts_for_need_id(101350, [
          {
            id: "http://contentapi.dev.gov.uk/vat-rates.json",
            web_url: "http://www.dev.gov.uk/vat-rates",
            title: "VAT rates",
            format: "answer"
          },
          {
            id: "http://contentapi.dev.gov.uk/vat.json",
            web_url: "http://www.dev.gov.uk/vat",
            title: "VAT",
            format: "business_support"
          }
        ])

        visit "/needs"
        click_on "101350"

        within ".need" do
          assert page.has_selector?("table#artefacts-for-need")

          within "table#artefacts-for-need" do
            assert page.has_selector?("tbody tr", count: 2)

            within "tbody" do
              within "tr:first-child" do
                assert page.has_link?("VAT rates", href: "http://www.dev.gov.uk/vat-rates")
                assert page.has_content?("Answer")
                assert page.has_content?("http://www.dev.gov.uk/vat-rates")
              end

              within "tr:nth-child(2)" do
                assert page.has_link?("VAT", href: "http://www.dev.gov.uk/vat")
                assert page.has_content?("Business support")
                assert page.has_content?("http://www.dev.gov.uk/vat")
              end
            end # within tbody
          end # within table
        end # within .need

      end # should display artefacts from the content api

      should "not display a table when there are no artefacts for this need" do
        content_api_has_artefacts_for_need_id(101350, [])

        visit "/needs"
        click_on "101350"

        # check the page has loaded correctly
        assert page.has_content?("Book a driving test")

        within ".need" do
          assert page.has_no_selector?("table#artefacts-for-need")
        end
      end

      should "not display a table when the Content API returns an error" do
        GdsApi::ContentApi.any_instance.expects(:for_need).once
                                  .with(101350)
                                  .raises(GdsApi::HTTPErrorResponse.new(500))

        visit "/needs"
        click_on "101350"

        # check the page has loaded correctly
        assert page.has_content?("Book a driving test")

        within ".need" do
          assert page.has_no_selector?("table#artefacts-for-need")
        end
      end
    end # context showing artefacts which meet the need

  end

  context "given a need with missing attributes" do
    setup do
      setup_need_api_responses(101500)
    end

    should "show basic information about the need" do
      visit "/needs"
      click_on "101500"

      within ".need" do
        within "header" do
          assert page.has_no_selector?(".need-organisations")

          assert page.has_content?("Book a driving test")
          assert page.has_link?("Edit need", href: "/needs/101500/edit")
        end

        within ".the-need" do
          assert page.has_content?("As a user \nI need to book a driving test \nSo that I can get my driving licence")
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
    setup do
      setup_need_api_responses(101700)
    end

    should "show basic information about the need" do
      visit "/needs"
      click_on "101700"

      within ".need" do
        within "header" do
          assert page.has_no_selector?(".need-organisations")

          assert page.has_content?("Find out news from government")
          assert page.has_link?("Edit need", href: "/needs/101700/edit")
        end

        within ".the-need" do
          assert page.has_content?("As a user \nI need to find out news from government \nSo that I know what government is doing")
        end

        assert page.has_content?("This need applies to all organisations.")
      end
    end
  end

  context "given a need which is out of scope" do
    setup do
      setup_need_api_responses(101800)
    end

    should "indicate that it is out of scope" do
      visit "/needs"
      click_on "101800"

      assert page.has_content?("This need is not in scope for GOV.UK")
      assert page.has_no_button?("Mark as out of scope")
    end
  end

  context "given a need which doesn't exist" do
    setup do
      need_api_has_no_need("101007")
    end

    should "display a not found error message" do
      visit "/needs/101007"

      assert page.has_content?("The page you were looking for doesn't exist.")
    end
  end

end

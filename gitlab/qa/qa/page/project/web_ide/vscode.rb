# frozen_string_literal: true

# VSCode WebIDE is built off an iFrame application therefore we are unable to use `qa-selectors`
module QA
  module Page
    module Project
      module WebIDE
        class VSCode < Page::Base
          view 'app/views/shared/_broadcast_message.html.haml' do
            element 'broadcast-notification-container'
            element 'close-button'
          end

          def has_file_explorer?
            has_element?('div[aria-label="Files Explorer"]')
          end

          def right_click_file_explorer
            has_element?('div.monaco-list-rows')
            find_element('div[aria-label="Files Explorer"]').right_click
          end

          def open_file_from_explorer(file_name)
            click_element("div[aria-label='#{file_name}']")
          end

          def click_inside_editor_frame
            click_element('.monaco-editor')
          end

          def within_file_editor(&block)
            within_element('.monaco-editor', &block)
          end

          def has_right_click_menu_item?
            has_element?('div.menu-item-check')
          end

          def click_new_folder_menu_item
            click_element('span[aria-label="New Folder..."]')
          end

          def click_upload_menu_item
            click_element('span[aria-label="Upload..."]')
          end

          def enter_new_folder_text_input(name)
            find_element('input[type="text"]')
            send_keys(name, :enter)
          end

          def enter_file_input(file)
            find_element('input[type="file"]', visible: false).send_keys(file)
          end

          def has_commit_pending_tab?
            has_element?('.scm-viewlet-label')
          end

          def click_commit_pending_tab
            click_element('.scm-viewlet-label', visible: true)
          end

          def click_commit_tab
            click_element('.codicon-source-control-view-icon')
          end

          def has_commit_message_box?
            has_element?('div[aria-label="Source Control Input"]')
          end

          def enter_commit_message(message)
            within_element('div[aria-label="Source Control Input"]') do
              find_element('.view-line').click
              send_keys(message)
            end
          end

          def click_commit_button
            click_element('div[aria-label="Commit to \'main\'"]')
          end

          def has_notification_box?
            has_element?('.monaco-dialog-box')
          end

          def click_new_branch
            click_element('.monaco-button[title="Create new branch"]')
          end

          def has_branch_input_field?
            has_element?('input[aria-label="input"]')
          end

          def has_message?(content)
            within_vscode_editor do
              has_text?(content)
            end
          end

          def within_vscode_editor(&block)
            iframe = find('#ide iframe')
            page.within_frame(iframe, &block)
          end

          # Used for stablility, due to feature_caching of vscode_web_ide
          def wait_for_ide_to_load
            page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
            # On test environments we have a broadcast message that can cover the buttons
            if has_element?('broadcast-notification-container', wait: 5)
              within_element('broadcast-notification-container') do
                click_element('close-button')
              end
            end

            wait_for_requests
            Support::Waiter.wait_until(max_duration: 10, reload_page: page, retry_on_exception: true) do
              within_vscode_editor do
                # Check for webide file_explorer element
                has_file_explorer?
              end
            end
          end

          def create_new_folder(name)
            within_vscode_editor do
              # Use for stability, WebIDE inside an iframe is finnicky, webdriver sometimes moves too fast
              Support::Waiter.wait_until(max_duration: 20, retry_on_exception: true) do
                right_click_file_explorer
                has_right_click_menu_item?
                click_new_folder_menu_item
                # Verify New Folder button is triggered and textbox is waiting for input
                enter_new_folder_text_input(name)
                has_text?(name)
              end
            end
          end

          def commit_and_push(file_name)
            commit_toggle(file_name)
            push_to_new_branch
          end

          def commit_toggle(message)
            within_vscode_editor do
              if has_commit_pending_tab?
                click_commit_pending_tab
              else
                click_commit_tab
              end

              has_commit_message_box?
              enter_commit_message(message)
              has_text?(message)
              click_commit_button
              has_notification_box?
            end
          end

          def push_to_new_branch
            within_vscode_editor do
              click_new_branch
              has_branch_input_field?
              # Typing enter to 'New branch name' popup to take the default branch name
              send_keys(:enter)
            end
          end

          def create_merge_request
            within_vscode_editor do
              has_element?('div[title="GitLab Web IDE Extension (Extension)"]')
              click_element('.monaco-button[title="Create MR"]')
            end
          end

          def upload_file(file_path)
            within_vscode_editor do
              # VSCode eagerly removes the input[type='file'] from click on Upload.
              # We need to execute a script on the iframe to stub out the iframes body.removeChild to add it back in.
              page.execute_script("document.body.removeChild = function(){};")

              # Use for stability, WebIDE inside an iframe is finnicky, webdriver sometimes moves too fast
              Support::Waiter.wait_until(max_duration: 20, retry_on_exception: true) do
                right_click_file_explorer
                has_right_click_menu_item?
                click_upload_menu_item
                enter_file_input(file_path)
              end
              # Wait for the file to be uploaded
              has_text?(file_path)
            end
          end

          def add_file_content(prompt_data)
            within_vscode_editor do
              click_inside_editor_frame
              within_file_editor do
                send_keys(:enter, :enter, prompt_data)
              end
            end
          end

          def verify_prompt_appears_and_accept(pattern)
            within_vscode_editor do
              within_file_editor do
                Support::Waiter.wait_until(max_duration: 30) do
                  page.text.match?(pattern)
                end
                send_keys(:tab)
              end
            end
          end

          def validate_prompt(pattern)
            within_vscode_editor do
              within_file_editor do
                page.text.match?(pattern)
              end
            end
          end
        end
      end
    end
  end
end

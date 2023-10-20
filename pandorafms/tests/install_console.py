#!/usr/bin/env python3
# Script to install the Pandora FMS Console.
import os
import sys
from pyvirtualdisplay import Display
from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException

# Are we running headless?
if ('DISPLAY' not in os.environ):
    display = Display(visible=0, size=(1920, 1080))
    display.start()

browser = webdriver.Firefox(timeout=15)

try:
    # Go to the installation page.
    browser.implicitly_wait(5)
    browser.get('http://localhost/pandora_console/install.php')
    assert("Pandora FMS - Installation Wizard" in browser.title)

    # Accept the license agreement.
    browser.find_element_by_xpath("//*[@id='step11']").click()
    browser.find_element_by_xpath("//*[@id='btn_accept']").click()

    # Fill-in the configuration form.
    browser.find_element_by_xpath("//*[@id='step3']").click()
    browser.find_element_by_name("pass").send_keys("pandora")
    browser.find_element_by_xpath("//*[@id='step4']").click()

    # Complete the installation.
    browser.implicitly_wait(900) # The installation is going to take a long time.
    browser.find_element_by_xpath("//*[@id='step5']").click()
    browser.implicitly_wait(5)
    assert("Installation complete" in browser.page_source)
    browser.find_element_by_name("rn_file").click()
except AssertionError as error:
    print("Error " + str(error) + ":\n" + browser.page_source)
    sys.exit(1)
except NoSuchElementException as error:
    print("Error " + str(error) + ":\n" + browser.page_source)
    sys.exit(1)

# Clean-up
browser.quit()
if ('DISPLAY' not in os.environ):
    display.stop()

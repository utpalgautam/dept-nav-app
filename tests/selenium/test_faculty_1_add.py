import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select

def test_add_faculty(driver, base_url):
    """Test Case: Add a new faculty member."""
    driver.get(f"{base_url}/faculties")
    
    # Wait for the page to load and the "Add Faculty" button to be clickable
    wait = WebDriverWait(driver, 10)
    add_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Add Faculty')]")))
    
    time.sleep(1)  # Delay for visual clarity
    add_btn.click()
    
    # Fill in the form
    time.sleep(1)
    driver.find_element(By.NAME, "name").send_keys("Selenium Test Faculty")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "email").send_keys("selenium.test@example.com")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "role").send_keys("QA Automation Specialist")
    
    # Select a building (picking the first available one)
    time.sleep(0.5)
    building_select = Select(driver.find_element(By.NAME, "building"))
    # Skip the "Select Building" placeholder
    options = building_select.options
    if len(options) > 1:
        building_select.select_by_index(1)
    
    # Select a floor
    time.sleep(0.5)
    floor_select = Select(driver.find_element(By.NAME, "floor"))
    floor_select.select_by_visible_text("1st Floor")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "cabin").send_keys("SEL-101")
    
    # Submit the form
    time.sleep(1)
    submit_btn = driver.find_element(By.XPATH, "//button[@type='submit']")
    submit_btn.click()
    
    # Verify the faculty was added (use Search to find it)
    time.sleep(2)
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    search_input.send_keys("Selenium Test Faculty")
    time.sleep(1)
    
    wait.until(EC.presence_of_element_located((By.XPATH, f"//span[text()='Selenium Test Faculty']")))
    
    print("Faculty added successfully.")
    time.sleep(2)

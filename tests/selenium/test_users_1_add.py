import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select

def test_add_user(driver, base_url):
    """Test Case: Add a new user."""
    driver.get(f"{base_url}/users")
    
    wait = WebDriverWait(driver, 10)
    add_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(@class, 'user-add-btn')]")))
    
    time.sleep(1)  # Delay for visual clarity
    add_btn.click()
    
    # Fill in the form
    time.sleep(1)
    driver.find_element(By.NAME, "name").send_keys("Selenium Test User")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "email").send_keys("selenium.user@example.com")
    
    # Select User Type
    time.sleep(0.5)
    role_select = Select(driver.find_element(By.NAME, "role"))
    role_select.select_by_visible_text("Faculty")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "department").send_keys("Computer Science")
    
    time.sleep(0.5)
    driver.find_element(By.NAME, "year").send_keys("2024")
    
    # Select Status
    time.sleep(0.5)
    status_select = Select(driver.find_element(By.NAME, "status"))
    status_select.select_by_visible_text("Active")
    
    # Submit the form
    time.sleep(1)
    submit_btn = driver.find_element(By.XPATH, "//button[contains(@class, 'user-form-save-btn')]")
    submit_btn.click()
    
    # Verify the user was added
    time.sleep(2)
    # Search for it to confirm
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    search_input.send_keys("Selenium Test User")
    time.sleep(1)
    
    wait.until(EC.presence_of_element_located((By.XPATH, f"//div[contains(@class, 'user-name-text') and text()='Selenium Test User']")))
    
    print("User added successfully.")
    time.sleep(2)

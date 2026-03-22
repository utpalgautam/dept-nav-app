import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys

def test_edit_faculty(driver, base_url):
    """Test Case: Edit an existing faculty member."""
    driver.get(f"{base_url}/faculties")
    
    wait = WebDriverWait(driver, 10)
    
    # 1. Search for the faculty member
    time.sleep(1)
    search_input = wait.until(EC.presence_of_element_located((By.XPATH, "//div[@class='db-search-bar']/input")))
    search_input.clear()
    time.sleep(0.5)
    search_input.send_keys("Selenium Test Faculty")
    time.sleep(1) # Wait for search to filter
    
    # 2. Click "Edit Profile"
    edit_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//div[contains(@class, 'fac-table-row') and .//span[text()='Selenium Test Faculty']]//button[contains(text(), 'Edit Profile')]")))
    time.sleep(1)
    edit_btn.click()
    
    # 3. Modify the designation
    time.sleep(1)
    role_input = wait.until(EC.presence_of_element_located((By.NAME, "role")))
    role_input.clear()
    # If clear doesn't work well due to controlled component, use Backspace
    role_input.send_keys(Keys.CONTROL + "a")
    role_input.send_keys(Keys.BACKSPACE)
    time.sleep(0.5)
    role_input.send_keys("Senior QA Automation Specialist")
    
    # 4. Save the changes
    time.sleep(1)
    submit_btn = driver.find_element(By.XPATH, "//button[@type='submit']")
    submit_btn.click()
    
    # 5. Verify the update (wait for the table to reappear and the new role to be present)
    time.sleep(2)
    wait.until(EC.presence_of_element_located((By.XPATH, f"//span[text()='Senior QA Automation Specialist']")))
    
    print("Faculty edited successfully.")
    time.sleep(2)

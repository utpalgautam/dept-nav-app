import time
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select

def test_add_building(driver, base_url):
    """
    Test adding a new building with entry points.
    """
    driver.get(f"{base_url}/buildings")

    # 1. Verify Page Title
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CLASS_NAME, "db-title"))
    )
    assert "Buildings" in driver.find_element(By.CLASS_NAME, "db-title").text

    # 2. Add New Building
    add_btn = driver.find_element(By.CLASS_NAME, "buildings-add-btn")
    add_btn.click()
    time.sleep(2) # Increased delay
    print("Clicked Add Building button...")

    # Wait for Form to load
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.NAME, "name"))
    )

    # Fill Building Details
    driver.find_element(By.NAME, "name").send_keys("Automated Selenium Building")
    time.sleep(1)
    
    # Select Department
    dept_dropdown = driver.find_element(By.NAME, "department")
    select = Select(dept_dropdown)
    select.select_by_visible_text("Computer Science and Engineering")
    time.sleep(1)

    driver.find_element(By.NAME, "latitude").send_keys("12.345678")
    time.sleep(0.5)
    driver.find_element(By.NAME, "longitude").send_keys("77.123456")
    time.sleep(2) # Increased delay
    print("Filled building details...")

    # 3. Add Entry Point
    driver.find_element(By.NAME, "label").send_keys("Primary Entrance")
    time.sleep(1)
    
    ep_builder = driver.find_element(By.CLASS_NAME, "bf-ep-builder")
    ep_builder.find_element(By.NAME, "latitude").send_keys("12.345000")
    time.sleep(0.5)
    ep_builder.find_element(By.NAME, "longitude").send_keys("77.123000")
    time.sleep(1)
    
    driver.find_element(By.CLASS_NAME, "bf-add-ep-btn").click()
    time.sleep(2) # Increased delay
    print("Added entry point...")

    # 4. Save Building
    driver.find_element(By.CLASS_NAME, "bf-save-main-btn").click()
    time.sleep(4) # Significantly increased delay to see result
    print("Saving building...")

    # Wait for return to list view
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((By.CLASS_NAME, "building-card-name"))
    )

    # 5. Verify Building in List
    building_names = [el.text for el in driver.find_elements(By.CLASS_NAME, "building-card-name")]
    assert "Automated Selenium Building" in building_names

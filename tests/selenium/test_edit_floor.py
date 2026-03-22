import time
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_edit_floor(driver, base_url):
    """
    Test editing the floor created in "Automated Selenium Building".
    """
    driver.get(f"{base_url}/buildings")

    # 1. Search for the building
    time.sleep(3)
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, ".db-search-bar input"))
    )
    search_bar = driver.find_element(By.CSS_SELECTOR, ".db-search-bar input")
    search_bar.send_keys("Automated Selenium Building")
    time.sleep(4)
    print("Searching for building to edit floor...")

    # 2. Click View
    cards = driver.find_elements(By.CLASS_NAME, "building-card")
    found = False
    for card in cards:
        if "Automated Selenium Building" in card.find_element(By.CLASS_NAME, "building-card-name").text:
            view_btn = card.find_element(By.CLASS_NAME, "building-btn-view")
            view_btn.click()
            time.sleep(2)
            found = True
            break
    
    assert found, "The building was not found!"

    # 3. Switch to 'Edit Floor Map' tab
    tabs = driver.find_elements(By.CLASS_NAME, "bd-tab")
    for tab in tabs:
        if "Edit Floor Map" in tab.text:
            tab.click()
            time.sleep(2)
            break
    
    # 4. Select the floor to edit
    # The edit form uses an input with list="floors-list"
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, "input[list='floors-list']"))
    )
    floor_select_input = driver.find_element(By.CSS_SELECTOR, "input[list='floors-list']")
    
    # We need to find the floor ID. Since we don't know the generated ID, we can try to pick the first option from the datalist
    # Or just type 'Floor 1' if the component handles it. 
    # Actually, the onChange handler expects an ID. 
    # Let's try to get the ID from the datalist options.
    options = driver.find_elements(By.CSS_SELECTOR, "#floors-list option")
    if options:
        floor_id = options[0].get_attribute("value")
        floor_select_input.send_keys(floor_id)
        time.sleep(2)
    else:
        pytest.fail("No floors available to edit!")

    # 5. Modify Floor Name
    # The edit form rows match the add form but are in the second tab
    # I'll use the specific type/placeholder again
    edit_name_input = driver.find_element(By.CSS_SELECTOR, "form.bd-form:nth-of-type(1) input[placeholder='e.g. Ground Floor']")
    # Wait, there are two forms in BuildingDetails if matched by class. I should target the one that is visible.
    # Actually they are rendered conditionally in React.
    name_input = driver.find_element(By.CSS_SELECTOR, "input[placeholder='e.g. Ground Floor']")
    name_input.clear()
    name_input.send_keys("Testing Floor 1 - Edited")
    time.sleep(2)
    print("Modified floor name...")

    # 6. Submit Update
    update_btn = driver.find_element(By.CLASS_NAME, "bd-form__submit")
    update_btn.click()
    
    # Wait for success message
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CLASS_NAME, "bd-form__success"))
    )
    time.sleep(2)
    print("Floor updated successfully!")

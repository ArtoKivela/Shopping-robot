*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.HTTP
Library             Browser
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${ORDERS_PATH}              ${OUTPUT_DIR}${/}data${/}orders.csv
${RECEIPTS_PATH}            ${OUTPUT_DIR}${/}receipts
${SCREENSHOTS_PATH}         ${OUTPUT_DIR}${/}browser${/}screenshot

${LEG_INPUT_SELECTOR}
...                         \#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(3) > input


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders_table}=    Get orders
    FOR    ${row}    IN    @{orders_table}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    URLs
    New Context    acceptDownloads=${True}
    New Page    ${secret}[order]

Collect csv address from the user
    Add heading    Give The Orders CSV
    Add text input    address    label=Give the URL to the CSV file
    ${response}=    Run dialog
    RETURN    ${response.address}

Get orders
    ${csv_address}=    Collect csv address from the user
    RPA.HTTP.Download    ${csv_address}    target_file=${ORDERS_PATH}    overwrite=True
    ${orders_table}=    Read table from CSV    ${ORDERS_PATH}
    RETURN    ${orders_table}

Close the annoying modal
    Click    div.alert-buttons > button.btn.btn-danger

Fill the form
    [Arguments]    ${row}
    Select Options By    id=head    value    ${row}[Head]
    Check Checkbox    id=id-body-${row}[Body]
    Type Text    ${LEG_INPUT_SELECTOR}    ${row}[Legs]
    Type Text    id=address    ${row}[Address]

Preview the robot
    Hover    id=preview
    Mouse Button    click

Assert submit succeeded
    ${default_failure_keyword}=    Register Keyword To Run On Failure    NONE
    Get Element    id=receipt
    Register Keyword To Run On Failure    ${default_failure_keyword}

Click on the submit button
    Hover    id=order
    Mouse Button    click
    Assert submit succeeded

Submit the order
    Wait Until Keyword Succeeds    12x    0.5 sec    Click on the submit button

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Property    id=receipt    outerHTML
    ${pdf_path}=    Set Variable    ${RECEIPTS_PATH}${/}order-${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}
    RETURN    ${pdf_path}

Assert images loaded
    ${default_failure_keyword}=    Register Keyword To Run On Failure    NONE
    Get Element    \#robot-preview-image > img:nth-child(1)
    Get Element    \#robot-preview-image > img:nth-child(2)
    Get Element    \#robot-preview-image > img:nth-child(3)
    Register Keyword To Run On Failure    ${default_failure_keyword}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Assert images loaded
    Take Screenshot    screenshot-${order_number}    id=robot-preview-image
    RETURN    ${SCREENSHOTS_PATH}${/}screenshot-${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${pdf_items}=    Create List    ${pdf}    ${screenshot}:align=center
    Add Files To Pdf    ${pdf_items}    ${pdf}

Go to order another robot
    Hover    id=order-another
    Mouse Button    click

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}Receipts.zip
    Archive Folder With Zip    ${RECEIPTS_PATH}    ${zip_file_name}

*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Desktop
Library             OperatingSystem
Library             RPA.Archive


*** Variables ***
${ORDER_WEBSITE}=               https://robotsparebinindustries.com/#/robot-order
${ORDER_TABLE}=                 https://robotsparebinindustries.com/orders.csv
${GLOBAL_RETRY_AMOUNT}=         5x
${GLOBAL_RETRY_INTERVAL}=       0.5S


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    Fill the form    ${orders}
    Create ZIP package from PDF files
    [Teardown]    Close the robot order website


*** Keywords ***
Open the robot order website
    Open Available Browser    ${ORDER_WEBSITE}

Get orders
    Download    ${ORDER_TABLE}    overwrite=${TRUE}
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the annoying modal
    Click Button    css:button.btn.btn-dark

Fill the form
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Select From List By Index    name:head    ${order}[Head]
        Select Radio Button    body    ${order}[Body]
        Input Text
        ...    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(3) > input
        ...    ${order}[Legs]
        ...
        Input Text    address    ${order}[Address]
        Click Button    preview
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the form
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    order-another
    END

Submit the form
    Click Button    order
    Page Should Contain Element    receipt

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    Wait Until Page Contains Element    receipt
    ${receipt_html}=    Get Element Attribute    receipt    outerHTML
    ${pdf}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${Order number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf}
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Wait Until Page Contains Element    robot-preview-image
    ${screenshot}=    Capture Element Screenshot
    ...    robot-preview-image
    ...    ${OUTPUT_DIR}${/}screenshot${/}${Order number}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}    ${TRUE}
    Close Pdf

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}

Close the robot order website
    Close Browser

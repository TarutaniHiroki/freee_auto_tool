require 'playwright'
require 'json'
require 'net/http'
require "date"
require "time"

require "google/apis/calendar_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require 'uri'
require "dotenv"

Dotenv.load
OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Google Calendar API Ruby Quickstart".freeze
CREDENTIALS_PATH = "credentials.json".freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "token.yaml".freeze
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY


def authorize
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "default"
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
end
  
# Initialize the API
service = Google::Apis::CalendarV3::CalendarService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Fetch the next 10 events for the user
calendar_id = "primary"
i=1
max=Date.new(Date.today.year, Date.today.month, -1).day
a=[]
for i in 1..max-1 do
    s = Date.new(Date.today.year, Date.today.month, i)
    e = Date.new(Date.today.year, Date.today.month, i+1)
    response = service.list_events(calendar_id,
                                max_results:   1,
                                single_events: true,
                                order_by:      "startTime",
                                time_min:      s.rfc3339,
                                time_max:      e.rfc3339)
    if response.items[0]!=nil
      if response.items[0].event_type!="outOfOffice"
        a.append(s)
        p a
      end
    end
    i=i+1
end

count=a.count
# binding.irb

Playwright.create(playwright_cli_executable_path: './node_modules/.bin/playwright') do |playwright|
  playwright.chromium.launch(headless: false) do |browser|
    page = browser.new_page;
    page.goto('https://accounts.secure.freee.co.jp/login/hr');
    page.fill('input[name="email"]', "hiroki.tarutani@techouse.jp");#自分のfreee会計のメールアドレスに変更
    page.fill('input[name="password"]', "HAjddE8.9GriWcB");#自分のfreee会計のパスワードに変更
    
    page.locator('.btn').click()
    page.goto('https://secure.freee.co.jp/expense_applications_v2/new');
    page.fill('input[id="input-title"]', "交通費の申請");


    gyosu=2#申請行数を入力
    #交通経路から経費入力する場合---------------------------------------------------------------------------
    page.locator('.line_creator_from_traffic_route___StyledDiv-sc-1b1rawf-0').click();
    page.fill('input[id="departure-station"]', "電車の始点");#始点の正式名称を入力
    page.locator('text=電車の始点').click();#始点の正式名称を入力
    page.fill('input[id="arrival-station"]', "電車の終点");#始点の正式名称を入力
    page.locator('text=電車の終点').click();#始点の正式名称を入力
    page.locator('text=経路検索').click();

    #がんばる
    page.locator('text=820').first().click();
    page.locator('text=820').nth(1).click();
    page.locator('text=820').nth(2).click();
    page.locator('text=820').nth(3).click();
    page.locator('text=820').nth(4).click();
    page.locator('text=選択').nth(10).click();
    page.locator('.vb-mr100').nth(8).click();
    page.locator('.vb-tableListCell__link').first().click();
    page.fill('textarea[aria-label="内容"]', "内容（必須）");#詳細を記述
    #------------------------------------------------------------------------------------
    

    #手動で経費入力の場合---------------------------------------------------------------------
    page.locator('text=手動で経費入力').click();
    page.locator('.vb-mr100').nth(12).click();
    page.locator('.vb-tableListCell__link').first().click();
    page.locator('.vb-textarea--height3').nth(1).fill("内容（必須）")#詳細を記述
    page.fill('.vb-textField--alignRight',"交通費合計");#交通費合計を入力
    
    #------------------------------------------------------------------------------------

    #ここの中にコピー----------------------------------

    #------------------------------------------------------------------------------------

    for i in 1..count-1
        for j 1..gyosu do
          page.locator('.vb-iconOnlyButton').nth(4j-3).click();
        end
    end
    page.locator('.vb-textField--withIcon').first.fill(a[0]);
    if gyosu>1
      for i 2..gyosu do
        page.locator('.vb-textField--withIcon').nth(i-1).fill(a[0]);
      end
    end
    
    for i in 1..count-1
        for j 0..gyosu-1 do
            page.locator('.vb-textField--withIcon').nth(gyosu*i+j).fill(a[i]);
        end
      
        i=i+1
    end
    page.locator('text=下書き保存').click();
    binding.irb
  end
end

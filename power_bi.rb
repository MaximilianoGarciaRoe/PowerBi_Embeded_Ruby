# frozen_string_literal: true

# Module for PowerBI reports
module PowerBi
  require 'uri'
  require 'net/http'
  require 'json'

  def get_access_token
    url = URI('https://login.windows.net/common/oauth2/token')

    request = Net::HTTP::Post.new(url)
    request['cache-control'] = 'no-cache'
    request.body = "grant_type=password&
                    scope=openid&
                    username=" + ENV['USERNAME_POWERBI'] + "&
                    password=" + ENV['PASSWORD_POWERBI'] + "&
                    client_id=" + ENV['CLIENT_ID_POWERBI'] + "&
                    resource=https%3A%2F%2Fanalysis.windows.net%2Fpowerbi%2Fapi&
                    undefined="
    response = Net::HTTP.start(url.host, url.port,
                               use_ssl: url.scheme == 'https') { |http| http.request request }
    eval(response.body)[:access_token]
  end

  def get_reports_by_group_id(group_id, token)
    url = URI('https://api.powerbi.com/v1.0/myorg/groups/' + group_id + '/reports')

    request = Net::HTTP::Get.new(url)
    request['Authorization'] = 'Bearer ' + token
    request['cache-control'] = 'no-cache'

    response = Net::HTTP.start(url.host, url.port,
                               use_ssl: url.scheme == 'https') { |http| http.request request }
    reports = eval(response.body)[:value]

    reports_data = []

    reports.each do |report|
      next unless report[:name] != 'Report Usage Metrics Report'

      report_info = { name: report[:name],
                      group_id: group_id,
                      report_id: report[:id],
                      embed_url: report[:embedUrl] }
      reports_data.append(report_info)
    end

    reports_data.sort_by { |element| element[:name] }
  end

  def get_token_access_reports(group_id, report_id, token)
    url = URI('https://api.powerbi.com/v1.0/myorg/groups/' + group_id + '/reports/' + report_id + '/GenerateToken')

    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request['Authorization'] = 'Bearer ' + token
    request['cache-control'] = 'no-cache'
    request.body = 'accessLevel=view&undefined='

    response = Net::HTTP.start(url.host, url.port,
                               use_ssl: url.scheme == 'https') { |http| http.request request }

    eval(response.body)[:token]
  end

  def get_report_by_id(report_id, token)
    url = URI('ttps://api.powerbi.com/v1.0/myorg/reports/' + report_id)

    request = Net::HTTP::Get.new(url)
    request['Authorization'] = 'Bearer ' + token
    request['cache-control'] = 'no-cache'

    response = Net::HTTP.start(url.host, url.port,
                               use_ssl: url.scheme == 'https') { |http| http.request request }
    report = eval(response.body)[:value]

    report
  end
end

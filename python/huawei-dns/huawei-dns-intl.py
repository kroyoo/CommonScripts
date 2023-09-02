#!/usr/bin/env python
import requests
import json


class HuaweiCloudDnsApi:

    def __init__(self, line_filter=None, token=None, domain=None, subdomain=None, record_type='A'):
        if line_filter is None:
            line_filter = ['CN']
        self.dns_api = "https://dns.ap-southeast-1.myhuaweicloud.com"
        self.filtered_records = []
        self.default_records = []
        self.ips = []
        self.line_filter = line_filter
        self.record_dict = {line: [] for line in self.line_filter}

        self.domain = domain
        self.subdomain = subdomain
        self.record_type = record_type
        self.zone_id = None
        if token is None:
            self.get_tokens()
        else:
            self.token = token

    def _req(self, method='GEI', url='', headers=None, data=None, json=None):
        if headers is None:
            headers = {}
        response = requests.request(method, url, headers=headers, data=data, json=json)
        return response.json()

    def get_unique_ips(self, ips=None):
        # ips no empty return ips
        if ips is None:
            ips = []
        if len(ips) > 0:
            return list(set(ips))
        return list(set(self.ips))

    def get_tokens(self):
        url = "https://iam.ap-southeast-1.myhuaweicloud.com/v3/auth/tokens"
        headers = {
            "Content-Type": "application/json;charset=utf8"
        }
        data = {
            "auth": {
                "identity": {
                    "methods": ["password"],
                    "password": {
                        "user": {
                            "name": IAMUserName,
                            "password": IAMPassword,
                            "domain": {"name": IAMDomainName}
                        }
                    }
                },
                "scope": {
                    "project": {"name": "ap-southeast-1"}
                }
            }
        }

        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 201:
            self.token = response.headers.get('X-Subject-Token')
            print("Token:", self.token)
        else:
            print("Request failed with status code:", response.status_code)
            print("Response:", response.text)
            exit(1)

    def get_recordset(self):
        headers = {
            "X-Auth-Token": self.token
        }

        response = self._req("GET",
                             f"{self.dns_api}/v2.1/recordsets?name={self.domain}&status=ACTIVE",
                             headers)
        print(response)
        # if don't get ns record type, exit
        records = response.get('recordsets', [])
        if records is not None:
            self.zone_id = records[0].get('zone_id')
        else:
            exit(1)

        for record in records:
            name = f"{self.subdomain}.{self.domain}."
            if record.get('name') == name and record.get('type') == self.record_type:
                line = record.get('line')
                if line in self.line_filter:
                    self.record_dict[line].append(record)

    def build_recordset(self, line, ttl=10):
        return {
            "description": line,
            "weight": 1,
            "line": line,
            "name": f"{self.subdomain}.{self.domain}." if self.subdomain is not None else f"{self.domain}.",
            "records": self.get_unique_ips(),
            "ttl": ttl,
            "type": self.record_type,
            'tags': [
                {
                    'key': 'line',
                    'value': line
                }
            ]
        }

    def check_record(self):
        for line, records in self.record_dict.items():
            self.change_record(records, line)
        pass

    def change_record(self, records, line="CN"):
        method = 'PUT'
        if len(records) == 0:
            method = 'POST'
            url = f"{self.dns_api}/v2.1/zones/{self.zone_id}/recordsets"
            data = self.build_recordset(line, 1)
        else:
            url = f"{self.dns_api}/v2.1/zones/{self.zone_id}/recordsets/{records[0].get('id')}"
            data = {
                "name": records[0].get('name'),
                "type": records[0].get('type'),
                "records": self.get_unique_ips(),
                "ttl": 1
            }
        try:
            print(json.dumps(data))
            print(url)
            respone = requests.request(method, url,
                                       headers={
                                           "Content-Type": "application/json;charset=utf8",
                                           "X-Auth-Token": self.token
                                       },
                                       data=json.dumps(data))
            print(respone.json())
        except Exception as e:
            print(e)
            exit(1)

    def read_ips_file(self, filename):
        with open(filename, 'r') as file:
            for line in file:
                ip = line.strip()
                if ip and ip not in self.ips:
                    self.ips.append(ip)
                if len(self.ips) >= 5:
                    break
        if len(self.ips) == 0:
            print("IPs is empty")
            exit(1)


if __name__ == "__main__":
    IAMDomainName = 'Name of the account to which the IAM user belongs.'
    IAMUserName = 'IAM user name'
    IAMPassword = 'IAM user password.'
    token = None
    dns_api = "https://dns.ap-southeast-1.myhuaweicloud.com"
    client = HuaweiCloudDnsApi(['Abroad', 'CN'], token, 'domain.com', "cdn")
    client.get_recordset()
    client.read_ips_file('/codex/ips.txt')
    client.check_record()


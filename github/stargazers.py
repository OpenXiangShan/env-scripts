import argparse
import csv

from github import Github

location_cn = [
    "China",
    "beijing",
    "shanghai",
    "taiwan",
    "shenzhen",
    "wuhan",
    "tsinghua",
    "hong kong",
    "chengdu",
    "guangzhou",
    "taipei",
    "jilin",
    "tianjin",
    "hangzhou",
    "hongkong",
    "peking",
    "kunming",
    "nanjing",
    "jiangsu",
    "anhui",
    "chongqing",
    "p.r.c",
    "guangdong",
    "zhejiang",
    "yunnan",
    "xi'an",
    "urumchi",
    "yinchuan",
    "wuxi",
    "kunming",
    "suzhou",
    "changsha",
    "zhuhai",
    "prc",
    "shaanxi",
    "jiangxi",
    "hefei",
    "shenyang",
    "chinese",
    "guilin",
    "harbin",
    "深圳",
    "重庆",
    "北京",
    "上海",
    "杭州",
    "温州",
    # institutes
    "huazhong university",
    "Southern University of Science and Technology",
    "ByteDance",
    "Tongji University",
    "zhaoxin",
    "National Tsing Hua University",
    "Peking University",
    "Tencent",
    "Fudan University",
    "Chongqing University",
    "National Chiao Tung University",
    "iscas",
    "hkust",
    "University of Chinese Academy of Sciences",
    "ShanghaiTech University",
    "Harbin Institute of Technology",
    "Institute of Computing Technology",
    "alibaba",
    "Cambricon",
    "fudan",
    "Huazhong University of Sci & Tech",
    "Wuhan University of Technology",
    "Xiamen University",
    "The Hong Kong University of Science and Technology",
    "Shanghai Jiao Tong University",
    "Renmin University of China",
    "huawei",
    "Univ. of Science and Technology of China",
    "Chang Chun University of Technology",
    "Shanghai University",
    "NetEase",
    "Zhejiang University",
    "The Hong Kong Polytechnic University",
    "PingCAP",
    "kuaishou",
    "Nanjing Medical University",
    "Institute of Computing Technology",
    "Beihang University",
    "didi",
    "Chinese Academy of Sciences",
    "Microsoft Research Asia",
    "Nanjing University of Aeronautics and Astronautics",
    "Xi'an Jiaotong University",
    "Northwestern Polytechnical University",
    "baidu",
    "Tsinghua University",
    "Sun Yat-sen University",
    "Loongson",
    "iqiyi",
    "University of Electronic Science and Technology of China",
    "Peking University",
    "Sichuan University",
    "horizon",
    "hisilicon",
    "jd.com",
    "SUSTech",
    "Beijing University of Posts and Telecommunications",
    "National Taiwan University",
    "w3ctech",
    "National Chung Cheng University",
    "wubigo.com",
    # match all characters when all letters are upper cases
    "CN",
    "CAS",
    "UCAS"
    "THU",
    "SJTU",
    "ICT",
    "TJU",
    "CUHK",
    "BUAA",
    "HUST",
    "ZJU",
    "USTC",
    "HIT",
    "UESTC",
    # happy locations
    "bilibili",
    "gitee",
    "behind gfw",
    "jia li dun",
    "膜都",
    "陌生的城市啊熟悉的角落里",
    "肥宅行为模式研究院",
    "保密",
    "夏日萤火",
    "饮马河洛"
]

email_cn = [
    ".cn",
    ".hk",
    ".tw",
    "126.com",
    "163.com",
    "qq.com",
    "bytedance.com",
    "yeah.net",
    "sina.com",
    "aliyun.com",
    "tencent.com",
    "tetras.ai"
]

email_unknown = [
    "gmail.com",
    "outlook.com",
    "icloud.com",
    "hotmail.com",
    "foxmail.com",
    "msn.com"
]

location_unknown = [
    "Somewhere on this planet",
    "UFO",
    "Earth",
    "nowhere",
    "no",
    "our tiny round earth",
    "Mars",
    "somwhere, over the rainbow",
    "127.0.0.1",
    "0xfff"
]

# returns: (is_cn, is_others)
def is_cn(email, location, institute):
    for loc in location_cn:
        # match all characters when all letters are upper cases
        if loc.isupper():
            if loc in location or loc in institute:
                return True
            elif loc in email:
                print(f"Warning: email {email} matched with location {loc}")
                return True
        # do not care about upper or lower cases
        elif loc.lower() in location.lower() or loc.lower() in institute.lower():
            # print(f"Warning: matched  {location} {institute}")
            return True
        elif loc.lower() in email.lower():
            print(f"Warning: email {email} matched with location {loc}")
            return True
    for em in email_cn:
        if email.endswith(em):
            return True
    return False

def is_unknown(email, location, institute):
    if not location or location in location_unknown:
        if not institute or institute in location_unknown:
            if not email:
                return True
            else:
                return True in list(map(lambda s: email.endswith(s), email_unknown))
    return False

def load_from_github(token, output):
    if output is None:
        print("No output file is specified. Default to out.csv.")
        output = "out.csv"

    # using an access token
    g = Github(token)

    xs = g.get_repo("OpenXiangShan/XiangShan")
    stargazers = xs.get_stargazers()
    print(f"stars: {stargazers.totalCount}")

    all_info = []
    all_info.append(("login", "name", "email", "location", "company"))
    for i, s in enumerate(stargazers):
        all_info.append((s.login, s.name, s.email, s.location, s.company))
        print(f"{i}: {s.login}")

    write_to_csv(all_info, output)

    return all_info


def write_to_csv(info, filename):
    # write to csv
    with open(filename, 'w') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerows(info)


def load_from_csv(filename):
    all_info = []

    with open(filename, "r") as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=',')
        line_count = -1
        for row in csv_reader:
            line_count += 1
            if line_count == 0:
                print(f'Column names are {", ".join(row)}')
            else:
                all_info.append(row)
        print(f'Processed {line_count} lines.')

    return all_info


def main(token, input_csv, output_csv):
    if input_csv is None:
        stargazers = load_from_github(token, output_csv)
    else:
        stargazers = load_from_csv(input_csv)
    cn_list, others_list, unknown_list = [], [], []
    all_stars = len(stargazers)
    for star in stargazers:
        if is_cn(star[2], star[3], star[4]):
            cn_list.append(star)
        elif is_unknown(star[2], star[3], star[4]):
            unknown_list.append(star)
        else:
            others_list.append(star)
    print(f"cn:      {len(cn_list)} {len(cn_list) / all_stars}")
    print(f"others:  {len(others_list)} {len(others_list) / all_stars}")
    print(f"unknown: {len(unknown_list)} {len(unknown_list) / all_stars}")
    write_to_csv(cn_list, "cn.csv")
    write_to_csv(others_list, "others.csv")
    write_to_csv(unknown_list, "unknown.csv")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='stargazers analysis')
    parser.add_argument('--input', '-i', default=None, help='input file')
    parser.add_argument('--token', '-t', default=None, help='github token')
    parser.add_argument('--output', '-o', default=None, help='output csv file')

    args = parser.parse_args()

    main(args.token, args.input, args.output)


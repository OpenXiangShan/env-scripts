import argparse
import csv
import os
import sys
import time
import re
import requests
from io import StringIO

script_path = os.path.realpath(__file__)
perf_dir = os.path.join(os.path.dirname(script_path),"../perf")
sys.path.append(perf_dir)

import perf

from github import Github

def get_commit_messages(token, sha, repo_name="OpenXiangShan/GEM5"):
    g = Github(token)
    repo = g.get_repo(repo_name)
    return list(map(lambda s: repo.get_commit(s).commit.message.splitlines()[0], sha))

def get_recent_commits(token, number=10, repo_name="OpenXiangShan/GEM5"):
    g = Github(token)
    repo = g.get_repo(repo_name)
    try:
        actions = list(repo.get_workflow_runs(branch="xs-dev", event="push")[:5*number])
        filtered_actions = [a for a in actions if "Performance Test" in a.name][:number]
        recent_commits = list(map(lambda a: a.head_sha, filtered_actions))
        run_numbers = list(map(lambda a: a.run_number, filtered_actions))
        commit_messages = get_commit_messages(token, recent_commits, repo_name)
        return run_numbers, recent_commits, commit_messages
    except Exception as e:
        print(f"获取最近提交时出错: {str(e)}")
        return [], [], []

def download_gem5_artifact(token, repo_name, run_id, artifact_prefix="performance-score"):
    """下载GitHub Actions的artifact（支持前缀匹配）"""
    g = Github(token)
    repo = g.get_repo(repo_name)
    
    # 获取指定运行的artifacts
    workflow_run = repo.get_workflow_run(run_id)
    artifacts = workflow_run.get_artifacts()
    
    # 查找匹配前缀的artifact
    matched_artifact = None
    for artifact in artifacts:
        if artifact.name.startswith(artifact_prefix):
            matched_artifact = artifact
            print(f"找到匹配的artifact: {artifact.name}")
            break
    
    if matched_artifact:
        # 使用requests直接下载
        headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json"
        }
        
        # 获取下载URL
        response = requests.get(matched_artifact.archive_download_url, headers=headers)
        if response.status_code == 200:
            # 创建临时目录存储下载的文件
            tmp_dir = f"/tmp/gem5-artifacts-{run_id}"
            os.makedirs(tmp_dir, exist_ok=True)
            zip_path = os.path.join(tmp_dir, f"{matched_artifact.name}.zip")
            
            # 保存zip文件
            with open(zip_path, 'wb') as f:
                f.write(response.content)
            
            # 解压文件
            os.system(f"unzip -o {zip_path} -d {tmp_dir}")
            
            # 查找所有文本文件（.txt或.csv）
            print(f"在 {tmp_dir} 中查找分数文件...")
            result_files = []
            for root, dirs, files in os.walk(tmp_dir):
                for file in files:
                    if file.endswith('.txt') or file.endswith('.csv'):
                        result_files.append(os.path.join(root, file))
                        print(f"  找到文件: {os.path.join(root, file)}")
            
            if result_files:
                print(f"使用文件: {result_files[0]}")
                return result_files[0]  # 返回找到的第一个文件路径
            else:
                print(f"错误: 在 {tmp_dir} 中没有找到任何分数文件")
        else:
            print(f"错误: 无法下载 artifact, 状态码: {response.status_code}")
    else:
        print(f"错误: 未找到前缀为 {artifact_prefix} 的artifact")
        # 显示所有可用的artifacts
        print("可用的artifacts:")
        for artifact in artifacts:
            print(f"  - {artifact.name}")
    
    return None

def parse_gem5_spec_score(file_path):
    """解析GEM5 SPEC06分数文件"""
    results = {}
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # 只提取SPEC06整数分数
    int_pattern = r'================ Int ================\s+(.*?)================ FP ================'
    
    int_match = re.search(int_pattern, content, re.DOTALL)
    
    if int_match:
        int_section = int_match.group(1)
        # 解析整数基准测试
        int_benchmarks = {}
        for line in int_section.strip().split('\n'):
            if line.strip() and not line.startswith('time') and not line.startswith('Estimated'):
                parts = line.split()
                if len(parts) >= 4:
                    benchmark = parts[0]
                    score = parts[2]  # 分数在第三列
                    if score != 'NaN':
                        int_benchmarks[benchmark] = float(score)
        
        results['INT'] = int_benchmarks
    
    # 提取总体分数
    overall_pattern = r'Estimated Int score per GHz:\s+([\d\.]+)'
    overall_match = re.search(overall_pattern, content)
    if overall_match:
        results['Overall'] = float(overall_match.group(1))
    
    return results

def get_gem5_perf_data(token, run_id, repo_name="OpenXiangShan/GEM5"):
    """获取GEM5性能测试数据"""
    # 获取工作流名称
    g = Github(token)
    repo = g.get_repo(repo_name)
    workflow_run = repo.get_workflow_run(run_id)
    workflow_name = workflow_run.name
    
    # 下载性能数据
    artifact_path = download_gem5_artifact(token, repo_name, run_id, "performance-score")
    if not artifact_path:
        return {}
    
    # 解析性能数据
    results = {}
    parsed_data = parse_gem5_spec_score(artifact_path)
    
    # 根据工作流名称确定测试类型
    test_type = "performance-score"  # 默认类型
    if "Ideal BTB" in workflow_name:
        test_type = "ideal-btb-performance-score"
    
    # 将解析的数据与正确的测试类型关联
    results[test_type] = parsed_data
    
    return results

def get_gem5_master_performance(token, run_id, repo_name="OpenXiangShan/GEM5"):
    """获取GEM5主分支的最新性能数据"""
    g = Github(token)
    repo = g.get_repo(repo_name)
    
    # 获取当前工作流的名称，用于匹配相同类型的主分支工作流
    workflow_run = repo.get_workflow_run(run_id)
    workflow_name = workflow_run.name
    
    # 获取xs-dev分支最新的workflow runs
    try:
        actions = list(repo.get_workflow_runs(branch="xs-dev", event="push")[:20])
        if not actions:
            print("没有找到xs-dev分支上的workflow runs")
            return None
            
        # 寻找相同名称的工作流
        filtered_actions = [a for a in actions if a.name == workflow_name]
        
        if not filtered_actions:
            print(f"没有找到名称为'{workflow_name}'的工作流")
            return None
        
        # 使用最新的成功运行
        for action in filtered_actions:
            if action.conclusion == "success":
                # 下载并解析性能数据
                return get_gem5_perf_data(token, action.id, repo_name)
    except Exception as e:
        print(f"获取主分支性能数据时出错: {str(e)}")
    
    return None

def get_pr_previous_commit_performance(token, pr, current_commit_sha, current_workflow_name, repo_name="OpenXiangShan/GEM5"):
    """获取PR中上一个commit的性能测试结果"""
    g = Github(token)
    repo = g.get_repo(repo_name)
    
    # 获取PR的所有commits，按时间倒序排列
    pr_commits = list(pr.get_commits().reversed)
    if len(pr_commits) <= 1:
        return None  # 如果只有一个commit，没有上一个commit
    
    # 查找当前commit的索引
    current_index = None
    for i, commit in enumerate(pr_commits):
        if commit.sha == current_commit_sha:
            current_index = i
            break
    
    if current_index is None or current_index == len(pr_commits) - 1:
        return None  # 没有找到当前commit或它是最早的commit
    
    # 从当前commit之后开始查找（更早的commit）
    for i in range(current_index + 1, len(pr_commits)):
        previous_commit = pr_commits[i]
        print(f"  检查上一个commit: {previous_commit.sha}")
        
        # 查找此commit对应的相同类型的workflow runs
        try:
            actions = list(repo.get_workflow_runs(head_sha=previous_commit.sha))
            perf_actions = [a for a in actions if a.name == current_workflow_name and a.conclusion == "success"]
            
            if perf_actions:
                print(f"  找到上一个commit {previous_commit.sha} 的性能测试结果")
                return get_gem5_perf_data(token, perf_actions[0].id, repo_name)
        except Exception as e:
            print(f"  检查commit {previous_commit.sha} 时出错: {str(e)}")
            continue
    
    print("  没有找到PR中上一个commit的性能数据")
    return None

def compare_performance(pr_perf, compare_perf):
    """比较PR和另一个性能数据的差异"""
    if not pr_perf or not compare_perf:
        return {}
    
    comparison = {}
    
    # 比较每个测试类型
    for test_type in pr_perf:
        if test_type in compare_perf:
            test_comparison = {}
            
            # 比较INT基准测试
            if 'INT' in pr_perf[test_type] and 'INT' in compare_perf[test_type]:
                int_comparison = {}
                for benchmark in pr_perf[test_type]['INT']:
                    if benchmark in compare_perf[test_type]['INT']:
                        pr_score = pr_perf[test_type]['INT'][benchmark]
                        compare_score = compare_perf[test_type]['INT'][benchmark]
                        diff = ((pr_score - compare_score) / compare_score) * 100
                        int_comparison[benchmark] = {
                            'PR': pr_score,
                            'Compare': compare_score,
                            'Diff(%)': round(diff, 2)
                        }
                test_comparison['INT'] = int_comparison
            
            # 比较总体分数
            if 'Overall' in pr_perf[test_type] and 'Overall' in compare_perf[test_type]:
                pr_overall = pr_perf[test_type]['Overall']
                compare_overall = compare_perf[test_type]['Overall']
                overall_diff = ((pr_overall - compare_overall) / compare_overall) * 100
                test_comparison['Overall'] = {
                    'PR': pr_overall,
                    'Compare': compare_overall,
                    'Diff(%)': round(overall_diff, 2)
                }
            
            comparison[test_type] = test_comparison
    
    return comparison

def format_comparison_comment(comparison, commit_sha, compare_type="Master", workflow_name="Standard Performance Test"):
    """格式化性能比较结果为Markdown评论"""
    comment = [f"[Generated by GEM5 Performance Robot]"]
    comment.append(f"commit: {commit_sha}")
    comment.append(f"workflow: {workflow_name}")
    comment.append("")
    
    test_type_names = {
        "performance-score": "Standard Performance",
        "ideal-btb-performance-score": "Ideal BTB Performance"
    }
    
    for test_type, data in comparison.items():
        test_name = test_type_names.get(test_type, test_type)
        comment.append(f"## {test_name}")
        comment.append("")
        
        # 添加总体分数比较
        if 'Overall' in data:
            comment.append("### Overall Score")
            comment.append(f"| | PR | {compare_type} | Diff(%) |")
            comment.append("| --- | ---: | ---: | ---: |")
            overall = data['Overall']
            diff_str = f"{overall['Diff(%)']:.2f}"
            if overall['Diff(%)'] > 0:
                diff_str = f"+{diff_str} 🟢"
            elif overall['Diff(%)'] < 0:
                diff_str = f"{diff_str} 🔴"
            comment.append(f"| Score | {overall['PR']:.2f} | {overall['Compare']:.2f} | {diff_str} |")
            comment.append("")
        
        # 添加INT基准测试比较
        if 'INT' in data and data['INT']:
            comment.append("### INT Benchmarks")
            comment.append(f"| Benchmark | PR | {compare_type} | Diff(%) |")
            comment.append("| --- | ---: | ---: | ---: |")
            
            for benchmark, scores in sorted(data['INT'].items()):
                diff_str = f"{scores['Diff(%)']:.2f}"
                if scores['Diff(%)'] > 0:
                    diff_str = f"+{diff_str} 🟢"
                elif scores['Diff(%)'] < 0:
                    diff_str = f"{diff_str} 🔴"
                comment.append(f"| {benchmark} | {scores['PR']:.2f} | {scores['Compare']:.2f} | {diff_str} |")
            
            comment.append("")
    
    return "\n".join(comment)

def has_robot(comments, commit, workflow_name):
    """检查是否已经有机器人评论"""
    for comment in comments:
        find_robot_head = comment.find("[Generated by GEM5 Performance Robot]") != -1
        find_commit = comment.find(f"commit: {commit}") != -1
        find_workflow = comment.find(f"workflow: {workflow_name}") != -1
        if find_robot_head and find_commit and find_workflow:
            return True
    return False

def prepare_gem5_comment(token, commit_sha, run_id, pr=None, repo_name="OpenXiangShan/GEM5"):
    """准备GEM5 PR性能对比评论"""
    # 获取工作流名称
    g = Github(token)
    repo = g.get_repo(repo_name)
    workflow_run = repo.get_workflow_run(run_id)
    workflow_name = workflow_run.name
    
    print(f"  准备评论 - 工作流: {workflow_name}, commit: {commit_sha}")
    
    # 获取PR的性能测试结果
    pr_perf = get_gem5_perf_data(token, run_id, repo_name)
    if not pr_perf:
        print(f"  未找到 {commit_sha} 的性能数据")
        return False, ""
    
    print(f"  找到性能数据，测试类型: {list(pr_perf.keys())}")
    
    comments = []
    
    # 与主分支比较
    print("  获取主分支性能数据...")
    master_perf = get_gem5_master_performance(token, run_id, repo_name)
    if master_perf:
        print(f"  找到主分支性能数据，测试类型: {list(master_perf.keys())}")
        master_comparison = compare_performance(pr_perf, master_perf)
        if master_comparison:
            master_comment = format_comparison_comment(master_comparison, commit_sha, "Master", workflow_name)
            comments.append(master_comment)
    else:
        print("  未找到主分支性能数据")
    
    # 与上一个commit比较
    if pr:
        print(f"  查找PR #{pr.number} 中上一个commit的性能数据...")
        prev_perf = get_pr_previous_commit_performance(token, pr, commit_sha, workflow_name, repo_name)
        if prev_perf:
            print(f"  找到上一个commit的性能数据，测试类型: {list(prev_perf.keys())}")
            prev_comparison = compare_performance(pr_perf, prev_perf)
            if prev_comparison:
                prev_comment = format_comparison_comment(prev_comparison, commit_sha, "Previous Commit", workflow_name)
                comments.append(prev_comment)
        else:
            print("  未找到上一个commit的性能数据")
    
    if not comments:
        print("  没有生成任何比较评论")
        return False, ""
    
    # 将所有评论合并
    final_comment = "\n\n".join(comments)
    print(f"  生成评论成功，包含 {len(comments)} 个比较部分")
    return True, final_comment

def get_gem5_pull_requests(token, debug=False):
    """处理GEM5仓库的PR性能测试"""
    g = Github(token)
    gem5_repo = g.get_repo("OpenXiangShan/GEM5")
    
    # 获取PR相关的工作流运行，按创建时间倒序排列
    print("获取PR相关的工作流运行...")
    # 增加数量并包含所有状态的工作流（不仅仅是success）
    actions_iter = gem5_repo.get_workflow_runs(event="pull_request")[:200]
    actions = list(actions_iter)  # 将迭代器转换为列表
    print(f"找到 {len(actions)} 个PR相关的工作流运行")
    
    # 只处理成功完成的性能测试工作流
    perf_actions = [a for a in actions if "Performance Test" in a.name and a.conclusion == "success"][:75]
    print(f"其中 {len(perf_actions)} 个是成功完成的性能测试相关的工作流")
    
    if not perf_actions:
        print("没有找到性能测试相关的工作流，请确认仓库中有运行性能测试的PR")
        return
    
    # 获取所有开放的PR，建立SHA到PR的映射缓存 + PR中所有commits的映射
    print("构建PR缓存...")
    open_prs = list(gem5_repo.get_pulls(state="open"))
    print(f"找到 {len(open_prs)} 个开放的PR")
    
    sha_to_pr = {}
    pr_commits = {}  # PR number -> list of commit SHAs
    
    if debug:
        print("开放的PR详细信息:")
    
    for pr in open_prs:
        base_branch = pr.base.label.split(":")[-1]
        if debug:
            print(f"  PR #{pr.number}: '{pr.title}'")
            print(f"    HEAD SHA: {pr.head.sha}")
            print(f"    基础分支: {base_branch}")
        
        if base_branch == "xs-dev":
            # 缓存HEAD SHA
            sha_to_pr[pr.head.sha] = pr
            
            # 获取PR中所有commits的SHA
            try:
                commits = list(pr.get_commits())
                commit_shas = [c.sha for c in commits]
                pr_commits[pr.number] = commit_shas
                
                # 将PR中所有commits的SHA都映射到这个PR
                for sha in commit_shas:
                    sha_to_pr[sha] = pr
                
                if debug:
                    print(f"    ✅ 已缓存 (HEAD + {len(commit_shas)} commits)")
                    print(f"    Commits: {commit_shas[:3]}{'...' if len(commit_shas) > 3 else ''}")
            except Exception as e:
                if debug:
                    print(f"    ❌ 获取commits失败: {str(e)}")
                sha_to_pr[pr.head.sha] = pr
                if debug:
                    print(f"    ✅ 已缓存 (仅HEAD)")
        else:
            if debug:
                print(f"    ❌ 基础分支不是xs-dev，跳过")
    
    print(f"缓存了 {len(sha_to_pr)} 个commit SHA到PR的映射")
    
    # 检查特定PR (如398)的工作流状态
    pr_398_sha = None
    for pr in open_prs:
        if pr.number == 398:
            pr_398_sha = pr.head.sha
            break
    
    if pr_398_sha and debug:
        print(f"\n🔍 检查PR #398的所有工作流状态:")
        if 398 in pr_commits:
            pr_398_commits = pr_commits[398]
            print(f"  PR #398有 {len(pr_398_commits)} 个commits")
            
            # 检查每个commit的工作流
            for i, commit_sha in enumerate(pr_398_commits):
                commit_workflows = [a for a in actions if a.head_sha == commit_sha and "Performance Test" in a.name]
                if commit_workflows:
                    print(f"  Commit {i+1} ({commit_sha[:8]}):")
                    for j, action in enumerate(commit_workflows[:2]):
                        print(f"    {j+1}. ID {action.id}: {action.name}")
                        print(f"       状态: {action.status}, 结论: {action.conclusion}")
                        print(f"       创建时间: {action.created_at}")
    
    # 显示性能工作流的详细信息
    if debug:
        print(f"\n最近的 {min(10, len(perf_actions))} 个性能测试工作流:")
        for i, action in enumerate(perf_actions[:10]):
            print(f"  {i+1}. ID {action.id}: {action.name}")
            print(f"     HEAD SHA: {action.head_sha}")
            print(f"     状态: {action.status}, 结论: {action.conclusion}")
            print(f"     创建时间: {action.created_at}")
            if action.head_sha in sha_to_pr:
                pr = sha_to_pr[action.head_sha]
                print(f"     匹配PR: #{pr.number}")
            else:
                print(f"     ❌ 未匹配到开放PR")
    
    # 按PR分组处理工作流运行
    pr_workflows = {}
    skipped_count = 0
    
    for action in perf_actions:
        if action.head_sha in sha_to_pr:
            pr = sha_to_pr[action.head_sha]
            pr_number = pr.number
            if pr_number not in pr_workflows:
                pr_workflows[pr_number] = {
                    'pr': pr,
                    'workflows': []
                }
            pr_workflows[pr_number]['workflows'].append(action)
        else:
            skipped_count += 1
    
    print(f"找到 {len(pr_workflows)} 个开放的PR需要处理")
    print(f"跳过了 {skipped_count} 个无法匹配到开放PR的工作流")
    
    # 显示被处理的PR信息
    if pr_workflows:
        pr_numbers = sorted(pr_workflows.keys())
        print(f"将要处理的PR: {pr_numbers}")
        
        # 显示每个PR的工作流数量
        for pr_num in pr_numbers:
            workflow_count = len(pr_workflows[pr_num]['workflows'])
            if pr_num in pr_commits:
                commit_count = len(pr_commits[pr_num])
                print(f"  PR #{pr_num}: {workflow_count} 个工作流 ({commit_count} commits)")
            else:
                print(f"  PR #{pr_num}: {workflow_count} 个工作流")
    
    # 处理每个PR的工作流
    for pr_number, pr_data in pr_workflows.items():
        pull_request = pr_data['pr']
        workflows = pr_data['workflows']
        
        print(f"\n处理PR #{pr_number}: {pull_request.title}")
        if debug:
            print(f"  PR头部SHA: {pull_request.head.sha}")
            print(f"  工作流数量: {len(workflows)}")
        
        # 按创建时间排序工作流（最新的在前）
        workflows.sort(key=lambda x: x.created_at, reverse=True)
        
        # 获取已有的评论
        all_comments = list(map(lambda c: c.body, pull_request.get_issue_comments()))
        
        # 为每个工作流创建评论（如果还没有的话）
        processed_count = 0
        for i, action in enumerate(workflows):
            if debug:
                print(f"  处理工作流 {i+1}/{len(workflows)}: ID {action.id}")
                print(f"    提交SHA: {action.head_sha}")
                print(f"    工作流名称: {action.name}")
                print(f"    状态: {action.status}, 结论: {action.conclusion}")
                print(f"    创建时间: {action.created_at}")
            
            # 检查是否已有机器人评论
            if not has_robot(all_comments, action.head_sha, action.name):
                success, comment = prepare_gem5_comment(
                    token, 
                    action.head_sha, 
                    action.id, 
                    pull_request
                )
                if success:
                    print(f"    ✅ 创建评论成功，长度: {len(comment)} 字符")
                    pull_request.create_issue_comment(comment)
                    # 更新评论列表，避免重复处理
                    all_comments.append(comment)
                    processed_count += 1
                else:
                    if debug:
                        print(f"    ❌ 未找到性能数据")
            else:
                if debug:
                    print(f"    ⏭️  已有机器人评论，跳过")
        
        print(f"  PR #{pr_number} 处理完成，新增 {processed_count} 个评论")
    
    print(f"\n所有PR处理完成，共处理 {len(pr_workflows)} 个PR")

def main(token, output_csv=None, number=1, always_on=True, debug=False):
    error_count = 0
    while always_on:
        try:
            # 处理GEM5仓库的PR
            get_gem5_pull_requests(token, debug)
        except KeyboardInterrupt:
            sys.exit()
        except Exception as e:
            error_count += 1
            print(f"ERROR count {error_count}!!!!: {str(e)}")
        else:
            # 每5分钟检查一次PR
            time.sleep(300)
    
    # 非持续运行模式，只处理主分支commit数据
    if output_csv:
        run_numbers, commits, messages = get_recent_commits(token, number)
        print(f"处理了主分支的 {len(commits)} 个最近提交")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='GEM5 Performance Analysis')
    parser.add_argument('--token', '-t', default=None, help='GitHub token')
    parser.add_argument('--output', '-o', default=None, help='输出主分支数据的CSV文件')
    parser.add_argument('--number', '-n', default=1, type=int, help='分析的主分支提交数量')
    parser.add_argument('--always-on', '-a', default=True, action="store_true", help='持续检查PR')
    parser.add_argument('--no-always-on', dest='always_on', action="store_false", help='不持续检查PR')
    parser.add_argument('--debug', '-d', default=False, action="store_true", help='显示调试信息')

    args = parser.parse_args()

    main(
        args.token, 
        args.output, 
        args.number, 
        args.always_on,
        args.debug
    )

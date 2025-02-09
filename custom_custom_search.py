import requests
import json
import re

def main(query: str, target_rank_range: int) -> dict:
    # クレンジング処理（指定された記号を削除）
    query = re.sub(r'[\\n{}":]', '', query)
    
    # API キーとカスタム検索エンジン ID の設定
    api_key = "<カスタム検索エンジンのAPIキー>"
    cse_id = "<カスタム検索エンジンID>"
    url = "https://www.googleapis.com/customsearch/v1"
    
    # 検索パラメータの設定。num に target_rank_range の値を使用する
    params = {
        "key": api_key,
        "cx": cse_id,
        "q": query,
        "num": target_rank_range,
    }
    
    # APIへリクエスト送信して結果を取得
    response = requests.get(url, params=params)
    response.raise_for_status()
    data = response.json()
    
    # 取得した検索結果から各記事情報を整形（"rank", "title", "link", "snippet"）
    results = []
    for i, item in enumerate(data.get("items", []), start=1):
        results.append({
            "rank": i,
            "title": item.get("title", ""),
            "link": item.get("link", ""),
            "snippet": item.get("snippet", ""),
        })
    
    return {"result": json.dumps(results, ensure_ascii=False, indent=2)}
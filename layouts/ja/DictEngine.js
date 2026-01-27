.pragma library

// 辞書データ（読み → [候補1, 候補2, ...]）
var dictionary = {}

// 辞書が読み込み済みか
var isLoaded = false

// 辞書テキストをパースして読み込む
function loadDictionary(text) {
    dictionary = {}
    var lines = text.split('\n')
    
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (line === '' || line.charAt(0) === ';') continue  // 空行・コメントをスキップ
        
        // SKK形式: 読み /候補1/候補2/.../
        var spaceIndex = line.indexOf(' ')
        if (spaceIndex === -1) continue
        
        var reading = line.substring(0, spaceIndex)
        var rest = line.substring(spaceIndex + 1)
        
        // /候補1/候補2/ → ["候補1", "候補2"]
        var candidates = rest.split('/').filter(function(s) {
            return s !== ''
        })
        
        if (candidates.length > 0) {
            dictionary[reading] = candidates
        }
    }
    
    isLoaded = true
    console.log("Dictionary loaded: " + Object.keys(dictionary).length + " entries")
}

// 完全一致で変換候補を取得
function lookup(reading) {
    if (!isLoaded) return []
    if (reading in dictionary) {
        return dictionary[reading]
    }
    return []
}

// 前方一致で変換候補を取得（予測変換用）
function lookupPrefix(reading) {
    if (!isLoaded) return []
    if (reading === '') return []
    
    var results = []
    for (var key in dictionary) {
        if (key.indexOf(reading) === 0) {
            results.push({
                reading: key,
                candidates: dictionary[key]
            })
        }
    }
    
    // 読みが短い順にソート
    results.sort(function(a, b) {
        return a.reading.length - b.reading.length
    })
    
    return results
}

// 変換候補を取得（完全一致 + 前方一致の最初の候補）
function getCandidates(reading, maxCount) {
    if (!isLoaded) return []
    if (reading === '') return []
    maxCount = maxCount || 10
    
    var candidates = []
    
    // 完全一致を優先
    if (reading in dictionary) {
        var exact = dictionary[reading]
        for (var i = 0; i < exact.length && candidates.length < maxCount; i++) {
            candidates.push(exact[i])
        }
    }
    
    // 前方一致も追加（重複を除く）
    var prefix = lookupPrefix(reading)
    for (var j = 0; j < prefix.length && candidates.length < maxCount; j++) {
        var entry = prefix[j]
        if (entry.reading !== reading) {  // 完全一致は除く
            var firstCandidate = entry.candidates[0]
            if (candidates.indexOf(firstCandidate) === -1) {
                candidates.push(firstCandidate)
            }
        }
    }
    
    return candidates
}

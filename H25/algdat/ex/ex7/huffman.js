class Node {
    constructor(char, freq, left=undefined, right=undefined) {
        this.char = char
        this.freq = freq
        this.branches = {
            left: left,
            right: right
        }
    }
}

function generateTree(string) {
    if (string.length == 0) return

    let freq = string.split('').reduce((total, letter) => {
        total[letter] ? total[letter]++ : total[letter] = 1
        return total
    }, {})

    freq = Object.entries(freq)
        .sort(([,a],[,b]) => a-b)
        .reduce((r, [k, v]) => ({ ...r, [k]: v }), {});
    

    let priorityQueue = []
    for (let i = 0; i < Object.keys(freq).length; i++) {
        priorityQueue.push(new Node(Object.keys(freq)[i], freq[Object.keys(freq)[i]]));
    }

    while (priorityQueue.length > 1) {
        let left = priorityQueue[0],
            right = priorityQueue[1]    
        let newFreq = left.freq + right.freq
        priorityQueue.splice(0, 2)
        priorityQueue.push(new Node(undefined, newFreq, left, right))
        priorityQueue.sort((a, b) => a.freq - b.freq)
    }
    let root = priorityQueue[0]
    return root
}

function isEndNode(node) {
    if (node.left == undefined && node.right == undefined) {
        return true
    } else {
        return false
    }
}

function encodeStringHuffman(root, path, huffmanCode) {
    if (root == undefined) {
        return
    }
    
    if (isEndNode(root.branches)) {
        if (path.length > 0) {
            huffmanCode[root.char] = path
        } else {
            huffmanCode[root.char] = '1'
        }
    } 

    for (let [index, [key, value]] of Object.entries(Object.entries(root.branches))) {
        encodeStringHuffman(value, path + (index).toString(), huffmanCode)
    }
}

function encodeMessageHuffman(string, huffmanCode) {
    let message = ""
    for (let char of string) {
        message += huffmanCode[char]
    }
    return message
}

function decodeStringHuffman(root, string, decodedMessage="") {
    if (isEndNode(root.branches)) {
        while (root.freq > 0) {
            decodedMessage += root.char
            root.freq -= 1
        }
    } else {
        let index = -1
        while (index < string.length - 1) {
            [index, decodedMessage] = traverseHuffmanTree(root, index, string, decodedMessage)
        }
    }
    return decodedMessage
}

function traverseHuffmanTree(root, index, string, decodedMessage="") {
    if (root == undefined) {
        return
    }

    if (isEndNode(root.branches)) {
        decodedMessage += root.char
        return [index, decodedMessage]
    }

    index++
    if (string[index] == '0') {
        root = root.branches.left
    } else {
        root = root.branches.right
    }
    return traverseHuffmanTree(root, index, string, decodedMessage)
}

function huffmanEncode(string) {
    let huffmanTree = generateTree(string)
    let huffmanCode = {} 
    encodeStringHuffman(huffmanTree, '', huffmanCode)
    
    let encodedMessage = encodeMessageHuffman(string, huffmanCode)
    let decodedMessage = decodeStringHuffman(huffmanTree, encodedMessage, "")
    return [huffmanTree, huffmanCode, encodedMessage, decodedMessage]
}

const string_to_encode = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
let a = huffmanEncode(string_to_encode)
console.log(a[2].length)


input_string = "M ?  g9M "

def is_palindrome(input_string):
    length = len(input_string)
    i = 0
    j = length - 1

    while (i < j):
        char_left = input_string[i]
        char_right = input_string[j]

        while (char_left == " "):
            i += 1
            char_left = input_string[i]

        while (char_right == " "):
            j -= 1
            char_right = input_string[i]

        i += 1
        j -= 1

        print(char_left, char_right)

        if not (i < j):
            return "Input is a palindrome"
    
        ## Convert uppercase to lower case
        if (ord(char_left) >= 65 and ord(char_left) <= 90):
            char_left = chr(ord(char_left) + 32)

        if (ord(char_right) >= 65 and ord(char_right) <= 90):
            char_right = chr(ord(char_right) + 32)

        ## Wild card
        if (char_left == "?" or char_right == "?"):
            continue

        if (char_left != char_right):
            return "Input is not a palindrome"

    return "Input is a palindrome"

print(is_palindrome(input_string))


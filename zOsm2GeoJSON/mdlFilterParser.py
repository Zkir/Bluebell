import re
from copy import deepcopy


# CONSTRUCTORS FOR RULES AND LITERALS
# string constant
class l: # string constant
    def __init__(self, s):
        self.value = s

    def __str__(self):
        return self.value

    def match(self, s):
        return self.value == s

# string constant
class r: # string constant
    def __init__(self, s):
        self.value = s

    def __str__(self):
        return self.value

    def match(self, s):
        return not (re.fullmatch(self.value, s) is None)

class SyntaxTreeNode:
    def __init__(self, s):
        self.nodename = s
        self.nodevalue = ''
        self.children = []
        fully_matched = False

    def str_representation(self):
        s = self.nodename
        s = str(s) + ' ('
        for child in self.children:
            s= s + child.str_representation()
        s = s + ' ) '
        return s

    def __str__(self):
        s='[ '
        s = s + self.str_representation()
        s = s + ' ]'
        return s

    def get_tokens(self):
        tokens=[]
        if len(self.children) == 0:
            tokens.append(self.nodename)
        else:
            for child in self.children:
                tokens=tokens + child.get_tokens()
        return tokens

    def get_tokens_str(self):
        tokens = []
        if len(self.children) == 0:
            if self.nodevalue!='':
                tokens.append(str(self.nodevalue))
                #print('"' + str(self.nodevalue) + '"')
            else:
                tokens.append(str(self.nodename))

        else:
            for child in self.children:
                tokens = tokens + child.get_tokens_str()
        return tokens



#just a string constant

# GRAMMAR DEFINITION
GRAMMAR = [
    ['S', ['COMPLEX_EXPRESSION']],
    ['TAG',      [r(r'[\w:]+')]],   #Letters, underscore _ and column :
    ['VALUE',    [r(r'[^()=)]+')]], # Value can be anything, but we will exclude symbols used in this grammar, to make parsing a bit faster.
    ['EQ',       [l('=')]],
    ['OR',       [l('or')]],
    ['AND',      [l('and')]],
    ['NOT',      [l('not')]],
    ['OBRACKET', [l('(')]],
    ['CBRACKET', [l(')')]],
    ['COMPLEX_EXPRESSION', ['SIMPLE_EXPRESSION']],
    ['SIMPLE_EXPRESSION', ['TAG', 'EQ', 'VALUE']],

    ['COMPLEX_EXPRESSION', ['COMPLEX_EXPRESSION', 'OR', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['COMPLEX_EXPRESSION', 'AND', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['NOT', 'COMPLEX_EXPRESSION']],
    ['COMPLEX_EXPRESSION', ['OBRACKET', 'COMPLEX_EXPRESSION', 'CBRACKET']]
  
]


#1. TOKENIZE. Initial string is separated into the list of tokens.
def tokenize(s):
    tokens = []
    # 1. remove redundant spaces
    s = s.strip()
    s = s + ' '

    # 2. separate into tokens
    k = 0
    for i in range(len(s)):
        if s[i] == " ":
            token = s[k:i]
            if token != '':  # no need to add empty token
                tokens.append(token)
            k = i + 1

        if s[i] == "=":
            token = s[k:i]
            if token != '':  # no need to add empty token
                tokens.append(token)
            tokens.append('=')
            k = i + 1
    return tokens


#2. APPLY RULES.
#For each variant in the variant list we expand non-terminal lexeme to receive a new variant set.
def expand_node(variant, GRAMMAR):
    B = []
    if len(variant.children) == 0:
        lexeme = variant.nodename
        matching_rules = []
        for R in GRAMMAR:
            if R[0] == lexeme:
                matching_rules.append(R)

        if len(matching_rules) > 0:
            blnVariantMatched = True
            for R in matching_rules:
                variant1 = deepcopy(variant)
                for R1 in R[1]:
                    variant1.children.append(SyntaxTreeNode(R1))
                B.append(variant1)
                #print('B:' + str(variant1))
                #print('B: tokens' + str(variant1.get_tokens()))

    else:
        for i in range(len(variant.children)):
            C = expand_node(variant.children[i], GRAMMAR)
            for c in C:
                #print('c ' + str(c))
                variant1 = deepcopy(variant)
                variant1.children[i]= c
                B.append(variant1)

            if len(C)>0:
                break
            else:
                #B.append(deepcopy(variant))
                pass

    return B


def apply_grammar(A, GRAMMAR):
    blnAnyVariantTransformed = False
    B = []
    for variant in A:
        if not blnAnyVariantTransformed :
            new_variants= expand_node(variant, GRAMMAR)
            blnVariantMatched = (len(new_variants) > 0)
            if blnVariantMatched:
                B = B + new_variants
                blnAnyVariantTransformed = True
            else:
                B.append(deepcopy(variant))  # Just copy variant if it was not transformed. it will be removed later.
        else:
            B.append(deepcopy(variant))  # Just copy variant if it was not transformed. it will be removed later.
    return B, blnAnyVariantTransformed


#3. ELIMINATE
# variants, even partially expanded, are eliminated if they do not match string to be parsed
# obviously, only expanded lexemes are compared
def eliminate_non_matching_variants (A, tokens):
    B = []
    for v in A:
        variant = v.get_tokens()
        blnAcceptVariant = True
        if len(variant) > len(tokens):
            # There are more lexems in variant than in parsed string. Variant is too long!
            blnAcceptVariant = False

        for i in range(len(tokens)):
            if i < len(variant):
                if type(variant[i]) is str:  # it's non-terminal lexeme, it cannot be tested (NB: terminal lexemes are l, non terminal lexemes are str
                    break  # just skip variant,since it contains non-terminals, maybe it's correct after all lexemes expanded
                else:
                    if variant[i].match(tokens[i]):
                        # print('token matched! ' + tokens[i])
                        variant[i].nodevalue = tokens[i]
                    else:
                        # print('token NOT matched! ' + variant[i])
                        blnAcceptVariant = False
                        break
            else:
                # print('too short'+str(variant))
                blnAcceptVariant = False
                break
            # print("variant fully matched")
            v.fully_matched = True
        if blnAcceptVariant:
            B.append(v)
    return B

def assign_nodes_to_parsed_tree(variant, tokens):
    if len(variant.children) == 0:
        variant.nodevalue = tokens.pop(0)
    else:
        for child in variant.children:
            assign_nodes_to_parsed_tree(child, tokens)

    return None

#parse string according to GRAMMAR.
def parse_string(s):
    #1. tokenize
    tokens = tokenize(s)

    print(tokens)
    print('---')

    A = [SyntaxTreeNode("S"), ]  # initial rule
    #A = [SyntaxTreeNode("SIMPLE_EXPRESSION"), ]  # initial rule

    for variant in A:
        print(variant)
    print(' tokens: ' + str(variant.get_tokens()))

    for ii in range(5000):
        print()
        print('---')
        print('step ' + str(ii))
        # 2. produce.
        B, blnAnyVariantTransformed = apply_grammar(A, GRAMMAR)
        A = deepcopy(B)
        print(str(len(A)) + ' variants before elimination')

        # 3. eliminate non matched variants
        B = eliminate_non_matching_variants(A, tokens)
        A = deepcopy(B)


        print(str(len(A)) + ' variants after elimination')
        for variant in A:
            var_tokens= variant.get_tokens_str()
            print(var_tokens)
            #print(' tokens: ', end='')
            #for t in var_tokens:
            #    if type(t) is str:
            #        print(str(t), end=' ')
            #    else:
            #        print(t.value, end=' ')
            #print()

        # print (len(A))
        if not blnAnyVariantTransformed:
            print('no rules left!')
            print('Completed in ' + str(ii) + ' steps.')
            break

    for variant in A:
        assign_nodes_to_parsed_tree(variant, deepcopy(tokens))
    return A

#s = "( amenity=bank ) and atm=yes "
#s = "( landuse=harbour ) or ( industrial=port )"
s = "( amenity=atm ) or ( amenity=bank and atm=yes ) or ( building=bank )"


print(s)

A = parse_string(s)

print('parsing result:')
for variant in A:
    print(variant)
    print(' tokens: ', end='')
    var_tokens = variant.get_tokens_str()
    for t in var_tokens:
        if type(t) is str:
            print(t, end=' ')
        else:
            print(t.value, end=' ')
    print()

    print("-----------------------------------------")
   # variant.print_as_tree()
    print("-----------------------------------------")


print()
print("That's all, folks!")

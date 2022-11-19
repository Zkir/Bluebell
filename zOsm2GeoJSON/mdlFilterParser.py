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

        if len(str(self.nodevalue))>0:
            s = "'"+ str(self.nodevalue) + "'"
        else:
            s = str(self.nodename)
        if len (self.children) > 0:
            s = s + ' ['
            for child in self.children:
                s = s + child.str_representation()
            s = s + '] '
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
        if len(self.children) == 0 or (type(self.children[0].nodename) is r): #terminal lexeme
            tokens.append(str(self.nodename))

        else:
            for child in self.children:
                tokens = tokens + child.get_tokens_str()
        return tokens



#just a string constant

# GRAMMAR DEFINITION
# Terminals/atoms in UPPER case
# non-terminals in lower case 
GRAMMAR = [
    ['s', ['complex_expression']],
    ['complex_expression', ['complex_expression', 'OR', 'complex_expression']],
    ['complex_expression', ['complex_expression', 'AND', 'complex_expression']],
    ['complex_expression', ['NOT', 'complex_expression']],
    ['complex_expression', ['OP', 'complex_expression', 'CP']],
    ['complex_expression', ['simple_expression']],
    ['simple_expression', ['TAG', 'EQ', 'VALUE']],    
    ['TAG',      [r(r'[\w:]+')]],   #Letters, underscore _ and column :
    ['VALUE',    [r(r'[^()=)]+')]], # Value can be anything, but we will exclude symbols used in this grammar, to make parsing a bit faster.
    ['EQ',       [l('=')]],
    ['OR',       [l('or')]],
    ['AND',      [l('and')]],
    ['NOT',      [l('not')]],
    ['OP',       [l('(')]],
    ['CP',       [l(')')]]
  
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
            if (R[0] == lexeme) and (R[0][0].islower()):
                matching_rules.append(R)
         
        #apply rule     
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
    
    
def expand_node_terminals(variant, GRAMMAR):
    
    if len(variant.children) == 0:
        lexeme = variant.nodename
        matching_rules = []
        for R in GRAMMAR:
            if (R[0] == lexeme) and (R[0][0].isupper ()):
                matching_rules.append(R)
                
        #Check that there is only one rule for terminal. 
        if  len(matching_rules) > 1:
            raise Exception("Terminals should be unique")
         
        #apply rule     
        if len(matching_rules) > 0:
            blnVariantMatched = True
            for R in matching_rules:
                for R1 in R[1]:
                    variant.children.append(SyntaxTreeNode(R1))

    else:
        for i in range(len(variant.children)):
            expand_node_terminals(variant.children[i], GRAMMAR)
            

    return None


def apply_grammar(A, GRAMMAR):
    blnAnyVariantTransformed = False
    B = []
    for variant in A:
       
        new_variants= expand_node(variant, GRAMMAR)
        blnVariantMatched = (len(new_variants) > 0)
        if blnVariantMatched:
            B = B + new_variants
            blnAnyVariantTransformed = True
        else:
            B.append(deepcopy(variant))  # Just copy variant if it was not transformed. it will be removed later.
            
    for variant in B:        
        #separate process for terminal lexemes, they can be processed in place
        expand_node_terminals(variant, GRAMMAR)
        
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
        else:  
            j = 0
            k = 0
            blnMaySkipTokens = False
            blnContainNonTerminals = False
            for i in range(len(variant)):
              
                if type(variant[i]) is str:  # it's non-terminal lexeme, it cannot be tested (NB: terminal lexemes are l, non terminal lexemes are str
                    pass  # just skip variant,since it contains non-terminals, maybe it's correct after all lexemes expanded
                    blnMaySkipTokens = True
                    blnContainNonTerminals = True
                else:
                    blnTokenMatched = False
                    if k>=len(tokens):
                        pass
                    else:
                        if blnMaySkipTokens:
                            for j in range (k,len(tokens)):
                                if variant[i].match(tokens[j]):
                                    # print('token matched! ' + tokens[i])
                                    blnTokenMatched = True
                                    blnMaySkipTokens = False
                                    variant[i].nodevalue = tokens[j]
                                    k = j + 1
                                    break
                        else:
                            if variant[i].match(tokens[k]):
                                # print('token matched! ' + tokens[i])
                                blnTokenMatched = True
                                blnMaySkipTokens = False
                                variant[i].nodevalue = tokens[k]
                                k = k + 1

                    if not blnTokenMatched:
                        # no such token found
                        blnAcceptVariant = False
                        break
            #all terminal tokens of variant are matched. But are there more tokens in the tail of original tokens?
            if (not blnContainNonTerminals) and ( len(variant) != len(tokens) ):
                #last token of varian is terminal and there are more tokens in original string
                blnAcceptVariant = False

            # print("variant fully matched")
            #v.fully_matched = True
            
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

    A = [SyntaxTreeNode("s"), ]  # initial rule
    #A = [SyntaxTreeNode("SIMPLE_EXPRESSION"), ]  # initial rule

    for variant in A:
        print(variant)
    print(' tokens: ' + str(variant.get_tokens()))

    for ii in range(30):
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

# convert tree to polish notation
def precompile_parsed_tree(variant, polish):

    if len(variant.children) == 0:
        polish.append(variant.nodevalue)
    else:
        if variant.nodename == "complex_expression":
            if len(variant.children) == 1:
                if variant.children[0].nodename == 'simple_expression':
                    precompile_parsed_tree(variant.children[0], polish)

            elif len(variant.children) == 2:
                # not
                if (variant.children[0].nodename == 'NOT') and (
                        variant.children[1].nodename == 'complex_expression'):
                    polish.append(variant.children[0].nodename)
                    precompile_parsed_tree(variant.children[1], polish)
                else:
                    raise Exception('unexpected node ' + str(variant))
            elif len(variant.children) == 3:
                # parenthesis
                if (variant.children[0].nodename == 'OP') and (variant.children[1].nodename == 'complex_expression') and (
                        variant.children[2].nodename == 'CP'):
                    precompile_parsed_tree(variant.children[1], polish)
                #or
                elif (variant.children[0].nodename == 'complex_expression') and (
                            variant.children[1].nodename == 'OR') and (
                            variant.children[2].nodename == 'complex_expression'):
                    polish.append(variant.children[1].nodename)
                    precompile_parsed_tree(variant.children[0], polish)
                    precompile_parsed_tree(variant.children[2], polish)
                # and
                elif (variant.children[0].nodename == 'complex_expression') and (
                            variant.children[1].nodename == 'AND') and (
                            variant.children[2].nodename == 'complex_expression'):
                    polish.append(variant.children[1].nodename)
                    precompile_parsed_tree(variant.children[0], polish)
                    precompile_parsed_tree(variant.children[2], polish)
                else:
                    raise Exception('unexpected node ' + str(variant))
            else:
                raise Exception ('unexpected node ' + str(variant) )

        elif variant.nodename == "simple_expression":
            # comparison
            if (variant.children[0].nodename == 'TAG') and (variant.children[1].nodename == 'EQ') and (
                    variant.children[2].nodename == 'VALUE'):
                polish.append(variant.children[1].nodename) #comparison operator
                polish.append(variant.children[0].nodename) #Tag
                polish.append('"'+variant.children[0].children[0].nodevalue+'"')  # tag
                polish.append('"'+variant.children[2].children[0].nodevalue+'"')  # Value
        else:
            for child in variant.children:
                precompile_parsed_tree(child, polish)

    return None

#=================================================================================
#s = "( not amenity=atm ) or ( amenity=bank )"
#s = "( landuse=harbour ) or ( industrial=port )"
s = "( amenity=atm ) or  ( amenity=bank and atm=yes ) and ( building=bank ) or ( test=test1 )"


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
    polish = []
    precompile_parsed_tree(variant, polish)
    for i in reversed(range (len(polish))):
            print(polish[i], end=' ')
    print()

    # variant.print_as_tree()
    print("-----------------------------------------")


print()
print("That's all, folks!")
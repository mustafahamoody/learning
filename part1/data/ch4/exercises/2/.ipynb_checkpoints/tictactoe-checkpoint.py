"""
Tic Tac Toe Player
"""

import math
import copy

X = "X"
O = "O"
EMPTY = None


def initial_state():
    """
    Returns starting state of the board.
    """
    return [[EMPTY, EMPTY, EMPTY],
            [EMPTY, EMPTY, EMPTY],
            [EMPTY, EMPTY, EMPTY]]


def player(board):
    """
    Returns player who has the next turn on a board.
    """
    counter = {X: 0, O: 0}
    # Record number of X and O on board
    for row in board:
        for cell in row:
            counter[cell] = counter.get(cell, 0) + 1
    # print(counter)
    # Returns player with lesser moves, or X if start (same moves)
    return O if (counter[O] < counter[X]) else X


def actions(board):
    """
    Returns set of all possible actions (i, j) available on the board.
    """
    actionSet = set()
    rowPos, cellPos = 0, 0
    # Itterate through board, listing positions of empty cells
    for row in board:
        for cell in row:
            # print(cell)
            if cell == EMPTY: 
                actionSet.add((rowPos, cellPos))
            cellPos += 1
        # print(row)
        rowPos += 1
        cellPos = 0
    return actionSet


def result(board, action):
    """
    Returns the board that results from making move (i, j) on the board.
    """
    rowPos, cellPos = action  # gets poition from action
    # Verifies positions are in board range (0, 3) exclusive
    if rowPos not in range(0, 3) or cellPos not in range(0, 3):
        raise NameError("Invalid Position")
    cpyBoard = copy.deepcopy(board)  # Makes deepcopy of board for result
    if cpyBoard[rowPos][cellPos] != EMPTY: 
        raise NameError("Invalid Action")  # Checks that action is valid
    # Applies action for current player onto deepcopy board
    cpyBoard[rowPos][cellPos] = player(board) 
    return cpyBoard
        

def winner(board):
    """
    Returns the winner of the game, if there is one.
    """
    def checkRow(board):
        for row in board:
            # Checks if all row elemnts are the same and not empty
            if len(set(row)) == 1 and EMPTY not in row:  
                return row[0]  # returns the (single) winning value in row
   
    if checkRow(board) is not EMPTY:
        return checkRow(board)
    
    def checkCol(board):
        for i in range(0, 3):  # Each row
            col = set(board[j][i] for j in range(0, 3))  # set of collumn values
            if len(col) == 1 and EMPTY not in col:  # Checks if all col elemnts are the same and not empty
                return board[0][i]  # returns the (single) winning value in col
    
    if checkCol(board) is not EMPTY:
        return checkCol(board)

    def checkDiagonal(board):
        # set with all diagonal values board 0 to 3 exclusive
        diagonal = set(board[i][i] for i in range(0, 3)) 
        # Checks if all diagonal elemnts are the same and not empty
        if len(diagonal) == 1 and EMPTY not in diagonal:
            return board[0][0]
        # diagonal values backwards (0, 2), (1, 1), (2,0)
        diagonal = set(board[i][2 - i] for i in range(0, 3))
        if len(diagonal) == 1 and EMPTY not in diagonal:
            return board[0][2]
        
    if checkDiagonal(board) is not EMPTY:
        return checkDiagonal(board)


def terminal(board):
    """
    Returns True if game is over, False otherwise.
    """
    
    if winner(board) is not EMPTY or not any(EMPTY in row for row in board):
        return True
    
    return False


def utility(board):
    """
    Returns 1 if X has won the game, -1 if O has won, 0 otherwise.
    """

    if winner(board) == X: 
        return 1
    elif winner(board) == O: 
        return -1
    else: 
        return 0


def minimax(board):
    """
    Returns the optimal action for the current player on the board.
    """
    
    def max_val(board):
        if terminal(board):
            return utility(board)
        # want to find better action to maximize score, and can always do better than this
        v = -float("inf")
        for action in actions(board):
            # finds a best case action
            if v == 1:
                return v
            v = max(v, min_val(result(board, action)))
        return v

    def min_val(board):
        if terminal(board):
            return utility(board)
        # want to find better action to minimize , and can always do better than this
        v = float("inf")
        for action in actions(board):
            # finds a best case action
            if v == -1:
                return v
            v = min(v, max_val(result(board, action)))
        return v
    
    if terminal(board): 
        return None

    currentPlayer = player(board)
    bestAction = None

    if currentPlayer == X:
        bestScore = -float("inf")
        for action in actions(board):
            score = min_val(result(board, action))
            if score > bestScore:
                bestScore = score
                bestAction = action
    
    else:
        bestScore = float("inf")
        for action in actions(board):
            score = max_val(result(board, action))
            if score < bestScore:
                bestScore = score
                bestAction = action
    
    return bestAction


"""
References

BYJU'S. (2022, September 30). Difference between list, tuple, set, and dictionary in Python. 
    BYJU'S. https://byjus.com/gate/difference-between-list-tuple-set-and-dictionary-in-python/ 

Efferalgan. (2016, October 7). Python - determine tic-tac-toe winner. Stack Overflow. 
    https://stackoverflow.com/questions/39922967/python-determine-tic-tac-toe-winner 

W3 Schools. (n.d.). Python - Add Set Items. W3 Schools. 
    https://www.w3schools.com/python/python_sets_add.asp 
"""
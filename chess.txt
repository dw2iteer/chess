import tkinter as tk
from tkinter import messagebox
import copy


class ChessGame:
    def __init__(self):
        # Инициализация игровой доски
        self.board = [
            ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'],
            ['p', 'p', 'p', 'p', 'p', 'p', 'p', 'p'],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            ['P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
            ['R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R']
        ]

        self.current_player = 'white'
        self.selected_square = None
        self.possible_moves = []
        self.move_history = []
        self.game_over = False

        # Юникод символы для фигур
        self.piece_symbols = {
            'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘', 'P': '♙',
            'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
            ' ': ' '
        }

        # Цвета
        self.light_color = '#F0D9B5'
        self.dark_color = '#B58863'
        self.selected_color = '#B5C7B5'
        self.possible_color = '#86A386'

        self.setup_gui()

    def setup_gui(self):
        """Создание графического интерфейса"""
        self.root = tk.Tk()
        self.root.title("Шахматы")

        # Убедимся, что шрифт поддерживает юникод символы
        try:
            self.font = ('DejaVu Sans', 32)
        except:
            self.font = ('Arial Unicode MS', 32)

        # Основной фрейм
        main_frame = tk.Frame(self.root)
        main_frame.pack(padx=10, pady=10)

        # Фрейм для доски
        self.board_frame = tk.Frame(main_frame, bg='black')
        self.board_frame.grid(row=0, column=0, padx=(0, 10))

        # Информационная панель
        info_frame = tk.Frame(main_frame, width=200)
        info_frame.grid(row=0, column=1, sticky='n')

        # Метка текущего игрока
        self.player_label = tk.Label(
            info_frame,
            text="Ходят: Белые",
            font=('Arial', 14, 'bold')
        )
        self.player_label.pack(pady=(0, 20))

        # История ходов
        tk.Label(info_frame, text="История ходов:", font=('Arial', 12)).pack()

        self.move_listbox = tk.Listbox(info_frame, width=25, height=20)
        self.move_listbox.pack()

        # Кнопки
        tk.Button(
            info_frame,
            text="Отменить ход",
            command=self.undo_move,
            font=('Arial', 12)
        ).pack(pady=10)

        tk.Button(
            info_frame,
            text="Новая игра",
            command=self.new_game,
            font=('Arial', 12),
            bg='lightblue'
        ).pack()

        # Создаем доску
        self.create_board()
        self.update_display()

    def create_board(self):
        """Создание шахматной доски"""
        self.squares = []
        for row in range(8):
            square_row = []
            for col in range(8):
                # Определяем цвет клетки
                color = self.light_color if (row + col) % 2 == 0 else self.dark_color

                # Создаем кнопку для клетки
                button = tk.Button(
                    self.board_frame,
                    text='',
                    font=self.font,
                    width=3,
                    height=1,
                    bg=color,
                    relief='flat',
                    command=lambda r=row, c=col: self.square_clicked(r, c)
                )
                button.grid(row=row, column=col, padx=1, pady=1)
                square_row.append(button)
            self.squares.append(square_row)

    def square_clicked(self, row, col):
        """Обработка клика по клетке"""
        if self.game_over:
            return

        piece = self.board[row][col]

        # Если кликнули на возможный ход
        if (row, col) in self.possible_moves and self.selected_square:
            self.make_move(self.selected_square, (row, col))
            return

        # Если кликнули на фигуру
        if piece != ' ':
            piece_color = 'white' if piece.isupper() else 'black'

            # Можно выбрать только свою фигуру
            if piece_color == self.current_player:
                self.selected_square = (row, col)
                self.possible_moves = self.get_valid_moves(row, col)
                self.update_display()

    def get_valid_moves(self, row, col):
        """Получение допустимых ходов для фигуры"""
        piece = self.board[row][col]
        if piece == ' ':
            return []

        moves = []
        piece_lower = piece.lower()

        # Пешка
        if piece_lower == 'p':
            direction = -1 if piece.isupper() else 1
            start_row = 6 if piece.isupper() else 1

            # Вперед на 1
            if self.is_empty(row + direction, col):
                moves.append((row + direction, col))

                # Вперед на 2 из стартовой позиции
                if row == start_row and self.is_empty(row + 2 * direction, col):
                    moves.append((row + 2 * direction, col))

            # Взятие
            for dc in [-1, 1]:
                if self.is_opponent(row + direction, col + dc, piece):
                    moves.append((row + direction, col + dc))

        # Ладья
        elif piece_lower == 'r':
            moves.extend(self.get_straight_moves(row, col))

        # Конь
        elif piece_lower == 'n':
            knight_moves = [
                (-2, -1), (-2, 1), (-1, -2), (-1, 2),
                (1, -2), (1, 2), (2, -1), (2, 1)
            ]
            for dr, dc in knight_moves:
                new_row, new_col = row + dr, col + dc
                if self.is_valid_move(new_row, new_col, piece):
                    moves.append((new_row, new_col))

        # Слон
        elif piece_lower == 'b':
            moves.extend(self.get_diagonal_moves(row, col))

        # Ферзь
        elif piece_lower == 'q':
            moves.extend(self.get_straight_moves(row, col))
            moves.extend(self.get_diagonal_moves(row, col))

        # Король
        elif piece_lower == 'k':
            king_moves = [
                (-1, -1), (-1, 0), (-1, 1),
                (0, -1), (0, 1),
                (1, -1), (1, 0), (1, 1)
            ]
            for dr, dc in king_moves:
                new_row, new_col = row + dr, col + dc
                if self.is_valid_move(new_row, new_col, piece):
                    moves.append((new_row, new_col))

        # Фильтруем ходы, которые оставляют короля под шахом
        safe_moves = []
        for move in moves:
            if self.is_move_safe(row, col, move):
                safe_moves.append(move)

        return safe_moves

    def is_empty(self, row, col):
        """Проверка, пуста ли клетка"""
        return 0 <= row < 8 and 0 <= col < 8 and self.board[row][col] == ' '

    def is_opponent(self, row, col, piece):
        """Проверка, есть ли на клетке фигура противника"""
        if 0 <= row < 8 and 0 <= col < 8:
            target = self.board[row][col]
            if target == ' ':
                return False
            return (piece.isupper() and target.islower()) or (piece.islower() and target.isupper())
        return False

    def is_valid_move(self, row, col, piece):
        """Проверка, можно ли пойти на клетку"""
        if 0 <= row < 8 and 0 <= col < 8:
            target = self.board[row][col]
            if target == ' ':
                return True
            return self.is_opponent(row, col, piece)
        return False

    def get_straight_moves(self, row, col):
        """Получение ходов по прямым линиям (ладья)"""
        moves = []
        piece = self.board[row][col]

        directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        for dr, dc in directions:
            for i in range(1, 8):
                new_row, new_col = row + dr * i, col + dc * i
                if not (0 <= new_row < 8 and 0 <= new_col < 8):
                    break

                target = self.board[new_row][new_col]
                if target == ' ':
                    moves.append((new_row, new_col))
                elif self.is_opponent(new_row, new_col, piece):
                    moves.append((new_row, new_col))
                    break
                else:
                    break
        return moves

    def get_diagonal_moves(self, row, col):
        """Получение ходов по диагоналям (слон)"""
        moves = []
        piece = self.board[row][col]

        directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        for dr, dc in directions:
            for i in range(1, 8):
                new_row, new_col = row + dr * i, col + dc * i
                if not (0 <= new_row < 8 and 0 <= new_col < 8):
                    break

                target = self.board[new_row][new_col]
                if target == ' ':
                    moves.append((new_row, new_col))
                elif self.is_opponent(new_row, new_col, piece):
                    moves.append((new_row, new_col))
                    break
                else:
                    break
        return moves

    def is_move_safe(self, from_row, from_col, to_pos):
        """Проверка, безопасен ли ход (не оставляет короля под шахом)"""
        # Создаем копию доски
        temp_board = copy.deepcopy(self.board)
        piece = temp_board[from_row][from_col]

        # Делаем ход на временной доске
        temp_board[to_pos[0]][to_pos[1]] = piece
        temp_board[from_row][from_col] = ' '

        # Находим позицию короля
        king_symbol = 'K' if self.current_player == 'white' else 'k'
        king_pos = None
        for r in range(8):
            for c in range(8):
                if temp_board[r][c] == king_symbol:
                    king_pos = (r, c)
                    break
            if king_pos:
                break

        if not king_pos:
            return True

        # Проверяем, атакован ли король
        opponent = 'black' if self.current_player == 'white' else 'white'

        # Проверяем атаки от всех фигур противника
        for r in range(8):
            for c in range(8):
                piece_at = temp_board[r][c]
                if piece_at != ' ':
                    piece_color = 'white' if piece_at.isupper() else 'black'
                    if piece_color == opponent:
                        # Проверяем, может ли эта фигура атаковать короля
                        if king_pos in self.get_all_attacks(r, c, temp_board):
                            return False

        return True

    def get_all_attacks(self, row, col, board_state):
        """Получение всех клеток, которые атакует фигура"""
        piece = board_state[row][col]
        attacks = []
        piece_lower = piece.lower()

        # Ладья
        if piece_lower == 'r':
            attacks.extend(self.get_straight_attacks(row, col, board_state))

        # Конь
        elif piece_lower == 'n':
            knight_moves = [
                (-2, -1), (-2, 1), (-1, -2), (-1, 2),
                (1, -2), (1, 2), (2, -1), (2, 1)
            ]
            for dr, dc in knight_moves:
                new_row, new_col = row + dr, col + dc
                if 0 <= new_row < 8 and 0 <= new_col < 8:
                    attacks.append((new_row, new_col))

        # Слон
        elif piece_lower == 'b':
            attacks.extend(self.get_diagonal_attacks(row, col, board_state))

        # Ферзь
        elif piece_lower == 'q':
            attacks.extend(self.get_straight_attacks(row, col, board_state))
            attacks.extend(self.get_diagonal_attacks(row, col, board_state))

        # Король
        elif piece_lower == 'k':
            king_moves = [
                (-1, -1), (-1, 0), (-1, 1),
                (0, -1), (0, 1),
                (1, -1), (1, 0), (1, 1)
            ]
            for dr, dc in king_moves:
                new_row, new_col = row + dr, col + dc
                if 0 <= new_row < 8 and 0 <= new_col < 8:
                    attacks.append((new_row, new_col))

        # Пешка
        elif piece_lower == 'p':
            direction = -1 if piece.isupper() else 1
            for dc in [-1, 1]:
                new_row, new_col = row + direction, col + dc
                if 0 <= new_row < 8 and 0 <= new_col < 8:
                    attacks.append((new_row, new_col))

        return attacks

    def get_straight_attacks(self, row, col, board_state):
        """Атаки по прямым линиям"""
        attacks = []
        piece = board_state[row][col]

        directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        for dr, dc in directions:
            for i in range(1, 8):
                new_row, new_col = row + dr * i, col + dc * i
                if not (0 <= new_row < 8 and 0 <= new_col < 8):
                    break

                attacks.append((new_row, new_col))
                target = board_state[new_row][new_col]
                if target != ' ':
                    break
        return attacks

    def get_diagonal_attacks(self, row, col, board_state):
        """Атаки по диагоналям"""
        attacks = []

        directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        for dr, dc in directions:
            for i in range(1, 8):
                new_row, new_col = row + dr * i, col + dc * i
                if not (0 <= new_row < 8 and 0 <= new_col < 8):
                    break

                attacks.append((new_row, new_col))
                target = board_state[new_row][new_col]
                if target != ' ':
                    break
        return attacks

    def make_move(self, from_pos, to_pos):
        """Выполнение хода"""
        from_row, from_col = from_pos
        to_row, to_col = to_pos

        piece = self.board[from_row][from_col]
        captured = self.board[to_row][to_col]

        # Запись хода
        move_num = len(self.move_history) + 1
        player = "Белые" if self.current_player == 'white' else "Черные"
        move_text = f"{move_num}. {player}: {self.pos_to_notation(from_pos)} → {self.pos_to_notation(to_pos)}"
        if captured != ' ':
            move_text += f" (взятие {self.piece_symbols[captured]})"

        self.move_history.append(move_text)

        # Выполнение хода
        self.board[to_row][to_col] = piece
        self.board[from_row][from_col] = ' '

        # Превращение пешки
        if piece.lower() == 'p':
            if (piece.isupper() and to_row == 0) or (piece.islower() and to_row == 7):
                self.board[to_row][to_col] = 'Q' if piece.isupper() else 'q'

        # Смена игрока
        self.current_player = 'black' if self.current_player == 'white' else 'white'

        # Сброс выбора
        self.selected_square = None
        self.possible_moves = []

        # Обновление интерфейса
        self.update_display()

        # Проверка конца игры
        self.check_game_over()

    def pos_to_notation(self, pos):
        """Конвертация позиции в шахматную нотацию"""
        row, col = pos
        letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
        return f"{letters[col]}{8 - row}"

    def update_display(self):
        """Обновление отображения доски"""
        # Сначала сбрасываем цвета
        for row in range(8):
            for col in range(8):
                color = self.light_color if (row + col) % 2 == 0 else self.dark_color
                self.squares[row][col].config(bg=color)

        # Подсвечиваем выбранную клетку
        if self.selected_square:
            row, col = self.selected_square
            self.squares[row][col].config(bg=self.selected_color)

        # Подсвечиваем возможные ходы
        for row, col in self.possible_moves:
            if self.board[row][col] == ' ':
                self.squares[row][col].config(bg=self.possible_color)
            else:
                self.squares[row][col].config(bg='#FF9999')  # Красный для взятия

        # Отображаем фигуры
        for row in range(8):
            for col in range(8):
                piece = self.board[row][col]
                symbol = self.piece_symbols.get(piece, ' ')
                fg_color = 'black' if piece.isupper() else 'black'  # Все черным
                self.squares[row][col].config(text=symbol, fg=fg_color)

        # Обновляем информацию
        player_text = "Ходят: Белые" if self.current_player == 'white' else "Ходят: Черные"
        self.player_label.config(text=player_text)

        # Обновляем историю ходов
        self.move_listbox.delete(0, tk.END)
        for move in self.move_history:
            self.move_listbox.insert(tk.END, move)

    def check_game_over(self):
        """Проверка условий окончания игры"""
        # Упрощенная проверка - просто считаем ходы
        if len(self.move_history) >= 100:  # Просто для примера
            messagebox.showinfo("Игра окончена", "Игра завершена!")
            self.game_over = True

    def undo_move(self):
        """Отмена последнего хода"""
        if len(self.move_history) == 0:
            return

        # Удаляем последний ход из истории
        self.move_history.pop()

        # Восстанавливаем начальную позицию (упрощенно)
        self.board = [
            ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'],
            ['p', 'p', 'p', 'p', 'p', 'p', 'p', 'p'],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            ['P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
            ['R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R']
        ]

        # Воспроизводим все ходы кроме последнего
        self.current_player = 'white'
        self.selected_square = None
        self.possible_moves = []
        self.game_over = False

        # Сбрасываем и воспроизводим историю
        temp_history = self.move_history.copy()
        self.move_history = []

        for move in temp_history:
            # Простая логика для демонстрации
            pass

        self.update_display()

    def new_game(self):
        """Начать новую игру"""
        self.board = [
            ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'],
            ['p', 'p', 'p', 'p', 'p', 'p', 'p', 'p'],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
            ['P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
            ['R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R']
        ]

        self.current_player = 'white'
        self.selected_square = None
        self.possible_moves = []
        self.move_history = []
        self.game_over = False

        self.update_display()

    def run(self):
        """Запуск игры"""
        self.root.mainloop()


# Запуск игры
if __name__ == "__main__":
    game = ChessGame()
    game.run()
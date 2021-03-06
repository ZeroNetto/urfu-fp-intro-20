{-
  02: Списки и строки

  В этой лекции мы познакомимся со списками и строками и
  научимся решать сложные задачи с помощью рекурсии.

-}

module Lecture02 where

-- Игнорируем некоторые функции стандартной библиотеки
import Prelude hiding
  ( head, take, head, map, foldr, reverse, sum
  , foldl, concat, sum, filter, length)

-- Но дополнительно импортируем снова, скрывая все функции
-- и переименовывая модуль как `P` (похоже на using в C#)
import qualified Prelude as P

{-
  Список в Haskell (и в других функциональных языках) определяется
  рекурсивно:
    - это либо пустой список

      []

    - либо элемент (голова) и другой список (хвост), соединяемые функцией (:):

      3 : [2, 1] :: List Int

  То есть список [1,2,3,4] на самом деле: 1 : (2 : (3 : (4 : []))).

  Специально для этого занятия мы определим свой список и стандартные функции для работы с ним,
  чтобы лучше понимать, как он устроен.

  `List a` — это полиморфный тип, который описывает список, содержащий элементы типа `a`.
  Вы уже сталкивались с подобной записью в других языках, например, в C# мы бы написали `LinkedList<T>`.
  
  Пока опустим то, как мы его объявили, нам достаточно понимать, что `a` — это тип элементов списка.
  
-}
data List a
  = Nil           -- соответствует []
  | a :. (List a) -- 
--        ^ хвост списка (просто другой список)
--    ^ функция склеивания головы и хвоста списка (соответствует стандартной (:))
--  ^ голова списка
  deriving (Eq, Show)

-- Так как мы определяем инфиксный оператор, то для удобства
-- зададим его приоритет как у стандартной функции (:):
infixr 5 :.

-- Табличка с приоритетами для других операций: https://rosettacode.org/wiki/Operator_precedence#Haskell

{-
  Примерный аналог определения списка на C#:

    public abstract class List<T> {}

    public class Nil<T> : List<T> {
      public Nil() {}
    }

    public class Cons<T> : List<T> {
      public T Value { get; private set; }
      public List<T> Tail { get; private set; }
    
      public Cons(T value, List<T> l) {
        Value = value;
        Tail = l;
      }
    }
-}

{-
  Тогда список [1, 2, 3, 4, 5] приобретает вид:
  
    1 :. 2 :. 3 :. 4 :. 5 :. Nil
-}

-- <Задачи для самостоятельного решения>

{-
  `headOr` возвращает первый элемент списка, если он присутствует:
    - headOr 5 (1 :. 2 :. 3 :. Nil) ~> 1
  или значение по умолчанию для пустого:
    - headOr 2 Nil ~> 2
-}
headOr :: a -> List a -> a
headOr = \d -> \case
  Nil -> d
  a :. _ -> a

{-
  `take n` возвращает первые `n` элементов списка:
    - take 2 (1 :. 2 :. 3 :. Nil) ~> (1 :. 2 :. Nil)
    - take 50 (1 :. 2 :. 3 :. Nil) ~> (1 :. 2 :. 3 :. Nil)
    - take 0 (1 :. 2 :. 3 :. Nil) ~> Nil
    - take (-4) (1 :. 2 :. 3 :. Nil) ~> Nil
-}
take :: Integer -> List a -> List a
take = go
  where
    go _ Nil = Nil
    go n (x :. xs)
      | n <= 0 = Nil
      | otherwise = x :. go (n - 1) xs

{-
  `length xs` возвращает длину списка `xs`:
    - length Nil ~> 0
    - length (1 :. Nil) ~> 1
    - length (1 :. 2 :. 3 :. Nil) ~> 3
    - length ('a' :. 'b' :. Nil) ~> 2
-}
length :: List a -> Integer
length = \case
  Nil -> 0
  _ :. xs -> 1 + length xs

{-
  `sum` вычисляет сумму списка целых чисел:
    - sum Nil ~> 0
    - sum (1 :. Nil) ~> 1
    - sum (1 :. 2 :. 3 :. Nil) ~> 6
    - sum (104 :. 123 :. 35 :. Nil) ~> 262
-}
sum :: List Integer -> Integer
sum = \case
  Nil -> 0
  a :. xs -> a + sum xs

-- </Задачи для самостоятельного решения>

{-
  Давайте посмотрим внимательно на функции length и sum, а точнее
  как они будут вычисляться:

    length (1 :. 2 :. 3 :. Nil)
  ~> 1 + length (2 :. 3 :. Nil)
  ~> 1 + (1 + length (3 :. Nil))
  ~> 1 + (1 + (1 + length Nil))
  ~> 1 + (1 + (1 + 0))
  ~> 3

    sum (1 :. 2 :. 3 :. Nil)
  ~> 1 + sum (2 :. 3 :. Nil)
  ~> 1 + (2 + sum (3 :. Nil))
  ~> 1 + (2 + (3 + sum Nil))
  ~> 1 + (2 + (3 + 0))
  ~> 6

  Обе функции ведут себя похоже: обходят список и что-то делают с
  элементом на каждом шаге. В случае функции length это добавление
  единицы, а sum прибавляет сам элемент. При этом они обе передают
  результат старого вычисления дальше.

  Если попытаться обобщить это поведение в какую-то одну функцию, то получится что-то вроде:

    fold f (10 :. 20 :. 30 :. Nil)
  ~> f 10 + (fold f (20 :. 30 :. Nil))
  ~> f 10 + (f 20 + fold f (30 :. Nil))
  ~> f 10 + (f 20 + (f 30 + fold f Nil))

  где f — любая функция с подходящим типом, а fold — функция-обобщение. Тогда:

    length = fold (\x -> 1)
    sum = fold (\x -> x)
  
  Сама функция fold (от англ. "свёртка") называется так потому,
  что мы сворачиваем список элементов в одно значение.

  А что если мы хотим не складывать элементы, а, например, умножать?
  Надо обобщить `fold` до использования любой бинарной функции и
  тогда ее выполнение примет следующий вид:
  
    foldr f x0 (1 :. 2 :. 3 :. Nil)
  ~> f 1 (foldr f x0 (2 :. 3 :. Nil))
  ~> f 1 (f 2 (foldr f x0 (3 :. Nil)))
  ~> f 1 (f 2 (f 3 (foldr f x0 Nil)))

  где f — любая функция, принимающая начальное значение и очередной элемент списка и
  возвращающая новое значение. Тогда:

    length = foldr (\x a -> a + 1) 0
    sum = foldr (\x a -> a + x) 0

  Получившаяся функция `foldr` — это функция высшего порядка, так как она принимает в качестве
  аргумента другую функцию. Вы уже сталкивались с функциями вышего порядка в других языках.
  
  Например, в таком LINQ выражении:
  
    list.Where(x => x > 0).ToList();
  
  `Where` тоже функция высшего порядка.
  
  На самом деле foldr это не одна функция, а целый набор функций-свёрток.
-}

-- <Задачи для самостоятельного решения>

{-
  `foldr f b xs` принимает на вход функцию `f`, начальное значение `b` и обходит
  список `xs` справа:

    - foldr (\x a -> a + 1) 0 [1, 2, 3, 4] ~> 4
    
    - foldr (\x a -> a + x) 0 [1, 2, 3, 4] ~> 10

    - foldr id 1234 Nil ~> 1234

    - foldr (\\x a -> a + 1) 0 ['c', 'r'] ~> 2

    - foldr (-) 0 [1, 2, 3, 4] ~> -2

      (1 - (2 - (3 - (4 - 0)))) = -2

        -
       / \
      1   -
         / \
        2   -
           / \
          3   -
             / \
            4   0
-}
foldr :: (a -> b -> b) -> b -> List a -> b
foldr f b xs = case xs of
  Nil -> b
  x :. ys -> f x (foldr f b ys)

{-
  `map` принимает функцию `f` и список, применяя `f` к каждому элементу:
  - map (\x -> x + 1) (1 :. 2 :. 3 :. Nil) ~> (2 :. 3 :. 4 :. Nil)
  - map id (1 :. 2 :. 3 :. Nil) ~> (2 :. 3 :. 4 :. Nil)
  - map (\x -> x + 1) Nil ~> Nil
  - map (\x -> "hi") (1 :. 2 :. 3 :. Nil) ~> ("hi" :. "hi" :. "hi" :. Nil)

  Реализуйте с помощью `foldr :: (a -> b -> b) -> b -> List a -> b`.
-}
map :: (a -> b) -> List a -> List b
map = \f xs -> foldr (\a b -> f a :. b) Nil xs

{-
  `filter` принимает предикат `f` и список, возвращая список с элементами
  удовлетворяющими предикату (когда f item == True):
  - filter (\x -> x >= 2) (1 :. 2 :. 3 :. Nil) ~> (2 :. 3 :. Nil)
  - filter (\x -> x >= 2) Nil ~> Nil
  - filter (\x -> x == 2) (1 :. 2 :. 3 :. Nil) ~> (2 :. Nil)
  - filter (\x -> length x == 2) ("hi" :. "hello" :. Nil) ~> ("hi" :. Nil)

  Реализуйте с помощью `foldr :: (a -> b -> b) -> b -> List a -> b`.
-}
filter :: (a -> Bool) -> List a -> List a
filter = \f xs -> foldr (\a b -> if f a then a :. b else b) Nil xs

{-
  Правая свёртка действует на список справа, с конца.

  Также есть и левая свертка, которая применяет функцию слева, начиная с начала списка.
  Поэтому аргументы для функции `f` идут в другом порядке. Примеры:

    foldl (\b _ -> b + 1) 0 [1,2,3,4] = ((((0 + 1) + 1) + 1) + 1) = 4

            +
           / \
          +   1
         / \
        +   1
       / \
      +   1
     / \
    0   1


    - foldl (\a x -> a + 1) 0 (1 :. 2 :. 3 :. 4 :. Nil) ~> 4

    - foldl (\a x -> a + x) 0 (1 :. 2 :. 3 :. 4 :. Nil) ~> 10

    - foldl (\a x -> x) 1234 Nil ~> 1234

    - foldl (-) 0 (1 :. 2 :. 3 :. 4 :. Nil) = ((((0 - 1) - 2) - 3) - 4) = -10

            -
           / \
          -   4
         / \
        -   3
       / \
      -   2
     / \
    0   1

  `foldl f b xs` принимает на вход функцию `f`, начальное значение `b` и обходит
  список `xs` слева:
-}
foldl :: (b -> a -> b) -> b -> List a -> b
foldl f b xs = case xs of
  Nil -> b
  x :. ys -> foldl f (f b x) ys

{-
  `reverse` разворачивает список:
    - reverse Nil ~> Nil
    - reverse (1 :. 2 :. 3 :. Nil) ~> (3 :. 2 :. 1 :. Nil)
    - reverse ('a' :. 'b' :. 'c' :. Nil) ~> ('c' :. 'b' :. 'a' :. Nil) 

  Реализуйте с помощью `foldl :: (b -> a -> b) -> b -> List a -> b`.
-}
reverse :: List a -> List a
reverse = foldl (flip (:.)) Nil

{-
  Пришло время перейти к стандартным спискам. Напишите функцию, которая
  конвертирует `List a` в `[a]`:

    - toListH (1 :. 2 :. 3 :. Nil) ~> [1, 2, 3]
    - toListH Nil ~> []

  Напоминаю, что:
    - Nil соответствует []
    - (:.) соответствует (:)
-}
toListH :: List a -> [a]
toListH = \case
  Nil -> []
  x :. xs -> x : toListH xs

-- И обратно
fromListH :: [a] -> List a
fromListH = \case
  [] -> Nil
  x : xs -> x :. fromListH xs

-- </Задачи для самостоятельного решения>

{-
  Функции `take`, `sum`, `reverse`, `foldl`, `foldr` и другие,
  уже присутствуют в стандартной библиотеке в модуле `Prelude`:
  https://hackage.haskell.org/package/base-4.12.0.0/docs/Prelude.html

  На самом деле они содержатся в `Data.List`:
  https://hackage.haskell.org/package/base-4.12.0.0/docs/Data-List.html

  а `Prelude` просто экспортирует небольшую часть.

  Помимо поддержки списков на уровне синтаксиса:

    - [], [1,2,3], ["hello"], ...
    - [Int], [String], ...

  в Haskell есть синтаксический сахар для удобной работы с списками:
  list comprehensions.

  Примеры:

    - [toUpper c | c <- "hello world"] ~> "HELLO WORLD"

    - [(i,j) | i <- [1,2], j <- [1..4]]

      ~> [(1,1),(1,2),(1,3),(1,4),(2,1),(2,2),(2,3),(2,4)]

  Помимо конечных списков можно работать и с бесконечными:

    - take 5 [ [ (i,j) | i <- [1,2] ] | j <- [1..] ]

      ~> [[(1,1),(2,1)], [(1,2),(2,2)], [(1,3),(2,3)], [(1,4),(2,4)], [(1,5),(2,5)]]

  Подробнее: https://wiki.haskell.org/List_comprehension
-}

-- Строки

{-
  Стандартный тип `String` для представления строк в Haskell является
  синонимом типа `[Char]`: 

  Prelude> :t "Hello world"
  "Hello world" :: [Char]

  То есть строка — это просто список символов. Из-за этого они редко
  используются в настоящих приложениях где важно потребление
  памяти и производительность. В качестве альтернативы типу `String` существуют
  `Text` и `ByteString`. Сейчас они нас не интересуют, но подробнее можно
  прочитать здесь:

  https://mmhaskell.com/blog/2017/5/15/untangling-haskells-strings

  Так как строки это списки, то и большинство функций для работы со строками
  содержатся в `Data.List`:
  https://hackage.haskell.org/package/base-4.12.0.0/docs/Data-List.html

  Поэтому `Data.String` такой небольшой:
  https://hackage.haskell.org/package/base-4.12.0.0/docs/Data-String.html
-}

-- <Задачи для самостоятельного решения>

{-
  Функция `concat` конкатенирует список списков в список:

    - concat [[12],[3],[4]] ~> [12,3,4]
    - concat ["hello ", "world"] ~> "hello world"

  Не забывайте, что строки конкатенируются при помощи `(++)`.

  Реализуйте при помощи P.foldr:

    P.foldr :: (a -> b -> b) -> b -> [a] -> b
-}
concat :: [[a]] -> [a]
concat ls = P.foldr (\b a -> b ++ a) [] ls

{-
  Функция `intercalate` вставляет список элементов между другими списками.
  Обычно это необходимо для конкатенации списков с разделителем:

    intercalate ", " ["hello", "world"] ~> "hello, world"

  P.S. работает как `join` в Python: ", ".join(["hello", "world"]) или C# string.Join(", ", list)

  Реализуйте при помощи P.foldr:

    P.foldr :: (a -> b -> b) -> b -> [a] -> b
-}
intercalate :: [a] -> [[a]] -> [a]
intercalate sep [] = []
intercalate sep ls =
  let l = last ls in P.foldr (\b a -> b ++ sep ++ a) [] (init ls) ++ l

-- </Задачи для самостоятельного решения>

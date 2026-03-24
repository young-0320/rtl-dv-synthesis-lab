# 과제 1

## 3월 27일 10:30 마감

zybo에 덧셈과 뺄셈이 되는 것을 genvar을 사용한 1bit adder을 기반으로 3비트 adder을 구성하고

LED로 출력하되 입력은 스위치와 버튼을 사용하시오.

하나는 cin을 사용해야 하고 또하나는 뺄샘인지 덧셈인지 구분하는 스위치.

LED로 값 출력.

잘 동작하는 것을 비디오 링크로 만들기.


## SPEC

unsigned int 3bit를 두 개 입력 받고, Full adder를 재사용하며 입력값(mode)으로 두 숫자를 더할지 뺄지를 선택


mode 0 : 덧셈

mode 1 : 뺄셈

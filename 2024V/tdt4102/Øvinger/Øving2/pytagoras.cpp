#ifndef PYTAGORAS_CPP
#define PYTAGORAS_CPP

#include "std_lib_facilities.h"
#include "AnimationWindow.h"

Point& operator+(Point& p1, const Point p2) {
    p1.x = p1.x + p2.x;
    p1.y = p1.y + p2.y;
    return p1;
}

void visualizePytagoras() {
    AnimationWindow window;

    // Triange size
    int a = 150;
    int b = 150;
    
    // Start draw position
    Point figure_start_point {b + 50, a + 50};
    
    // Draw triangle
    Point tri_1 {0, 0};
    Point tri_2 {0, b};
    Point tri_3 {a, b};

    tri_1 = tri_1 + figure_start_point;
    tri_2 = tri_2 + figure_start_point;
    tri_3 = tri_3 + figure_start_point;

    window.draw_triangle(tri_1, tri_2, tri_3, Color::black);

    // Draw squares
    // B-Side
    Point sq_B_1 {0, 0};
    Point sq_B_2 {0, b};
    Point sq_B_3 {-b, b};
    Point sq_B_4 {-b, 0};
    
    sq_B_1 = sq_B_1 + figure_start_point;
    sq_B_2 = sq_B_2 + figure_start_point;
    sq_B_3 = sq_B_3 + figure_start_point;
    sq_B_4 = sq_B_4 + figure_start_point;

    window.draw_quad(sq_B_1, sq_B_2, sq_B_3, sq_B_4, Color::green);

    // A-Side
    Point sq_A_1 {0, b};
    Point sq_A_2 {a, b};
    Point sq_A_3 {a, a+b};
    Point sq_A_4 {0, a+b};
    
    sq_A_1 = sq_A_1 + figure_start_point;
    sq_A_2 = sq_A_2 + figure_start_point;
    sq_A_3 = sq_A_3 + figure_start_point;
    sq_A_4 = sq_A_4 + figure_start_point;

    window.draw_quad(sq_A_1, sq_A_2, sq_A_3, sq_A_4, Color::red);
    
    // C-Side
    Point sq_C_1 {0, 0};
    Point sq_C_2 {b, -a};
    Point sq_C_3 {a+b, b-a};
    Point sq_C_4 {a, b};
    
    sq_C_1 = sq_C_1 + figure_start_point;
    sq_C_2 = sq_C_2 + figure_start_point;
    sq_C_3 = sq_C_3 + figure_start_point;
    sq_C_4 = sq_C_4 + figure_start_point;

    window.draw_quad(sq_C_1, sq_C_2, sq_C_3, sq_C_4, Color::blue);

    window.wait_for_close();
}

#endif

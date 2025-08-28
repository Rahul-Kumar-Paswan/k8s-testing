package com.rahulverse.controller;

import com.rahulverse.model.User;
import com.rahulverse.service.UserService;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class AuthController {

    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/register")
    public String register(User user, Model model) {
        User registered = userService.register(user);
        if (registered == null) {
            model.addAttribute("error", "Email already registered!");
            return "register";
        }
        model.addAttribute("message", "Registration successful! Please login.");
        return "login";
    }

    @PostMapping("/login")
    public String login(String email, String password, HttpSession session, Model model) {
        User loggedIn = userService.login(email, password);
        if (loggedIn != null) {
            session.setAttribute("user", loggedIn);
            return "redirect:/dashboard";
        }
        model.addAttribute("error", "Invalid credentials! Or register first.");
        return "login";
    }
}

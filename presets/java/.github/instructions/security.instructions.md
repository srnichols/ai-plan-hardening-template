---
description: Java security patterns — Spring Security, input validation, secrets management
applyTo: '**/*.java,**/application*.yml,**/application*.properties'
---

# Java Security Patterns

## Authentication & Authorization

### Spring Security Configuration
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**", "/health").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .build();
    }
}
```

### Method-Level Security
```java
@Service
public class UserService {

    @PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.id")
    public UserDto getUser(UUID userId) { ... }
}
```

## Input Validation

### Always validate at controller boundaries
```java
// ❌ NEVER: Trust input
@PostMapping("/users")
public User createUser(@RequestBody CreateUserRequest request) { ... }

// ✅ ALWAYS: Validate with @Valid
@PostMapping("/users")
public User createUser(@Valid @RequestBody CreateUserRequest request) { ... }

// ✅ Request DTO with validation annotations
public record CreateUserRequest(
    @NotBlank(message = "Name is required")
    @Size(max = 255)
    String name,

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    String email
) {}
```

### Custom Validation
```java
@Documented
@Constraint(validatedBy = TenantIdValidator.class)
@Target({FIELD, PARAMETER})
@Retention(RUNTIME)
public @interface ValidTenantId {
    String message() default "Invalid tenant ID";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

## Secrets Management

```java
// ❌ NEVER: Hardcoded secrets
String dbPassword = "secret123";

// ✅ ALWAYS: Externalized configuration
@Value("${spring.datasource.password}")
private String dbPassword;

// ✅ BEST: Environment variables or secret manager
// application.yml:
// spring.datasource.password: ${DB_PASSWORD}
```

## SQL Injection Prevention

```java
// ❌ NEVER: String concatenation
String sql = "SELECT * FROM users WHERE id = '" + id + "'";

// ✅ ALWAYS: Parameterized
String sql = "SELECT * FROM users WHERE id = ?";
jdbcTemplate.queryForObject(sql, rowMapper, id);
```

## CORS Configuration

```java
@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins("https://yourdomain.com")
                    .allowedMethods("GET", "POST", "PUT", "DELETE")
                    .allowedHeaders("*");
            }
        };
    }
}
```

## Common Vulnerabilities to Prevent

| Vulnerability | Prevention |
|--------------|------------|
| SQL Injection | Parameterized queries only |
| XSS | Response encoding, CSP headers |
| CSRF | Spring Security CSRF tokens |
| Mass Assignment | Use DTOs, never bind directly to entities |
| Insecure Deserialization | Validate input types, use records |

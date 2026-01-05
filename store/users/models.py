from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_ADMIN = 'admin'
    ROLE_GAMER = 'gamer'
    ROLE_SELLER = 'seller'
    ROLE_CHOICES = [
        (ROLE_ADMIN, 'Admin'),
        (ROLE_GAMER, 'Gamer'),
        (ROLE_SELLER, 'Seller'),
    ]

    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ROLE_GAMER)
    phone = models.CharField(max_length=30, blank=True)

    def __str__(self):
        return self.username
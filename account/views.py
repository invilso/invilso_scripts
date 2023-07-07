from django.conf import settings
from django.shortcuts import get_object_or_404, redirect, render
from django.views.generic.list import ListView
import requests
from account.serializer import UserSerializer
from django.contrib.auth.models import User
from rest_framework import permissions
from django.contrib import messages
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from django.utils.translation import gettext as _

from invilso_scripts.utils import is_human
from .models import Review, Profile
from django.db.models import ExpressionWrapper, F, Sum, Count
from django.db import models



class UsersView(ListCreateAPIView):
    queryset = User.objects.all()
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    serializer_class = UserSerializer


class UserView(RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'username'
    serializer_class = UserSerializer
    
def get_star_percentages(reviews):
    # create a dictionary to store the counts of each star rating
    star_counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
    # loop through the reviews and increment the corresponding star count
    for review in reviews:
        average = review.get_average_rating()
        # convert the percentage to an integer
        average = int(average)
        # round the average to the nearest star
        star = round(average)
        # increment the star count
        star_counts[star] += 1
    # create a list to store the percentages of each star rating
    star_percentages = []
    # loop through the star counts and calculate the percentage of each star rating
    for star, count in star_counts.items():
        # calculate the percentage as a fraction of the total number of reviews
        percentage = round(count / len(reviews) * 100)
        star_percentages.append({'stars': star, 'perc': percentage})
    return star_percentages

class ProfileView(ListView):
    def get(self, request, username):
        acc = get_object_or_404(User, username=username)
        reviews_all = acc.profile.reviews.all()
        all_reviews_len = reviews_all.count()
        if all_reviews_len > 0:
            reviews = reviews_all.aggregate(
                sum_rating=Sum(F('quality_of_service') + F('adherence_to_deadlines') +
                            F('communication_responsiveness') + F('price_value_ratio') +
                            F('overall_satisfaction')),
                total_reviews=Count('id')
            )

            total_reviews = reviews['total_reviews']
            sum_rating = reviews['sum_rating']

            average_rating = sum_rating / (total_reviews * 5) if total_reviews > 0 else 0.0
            star_percentages = get_star_percentages(reviews_all)[::-1]
        else:
            average_rating = 0
            star_percentages = [
                {'stars': 5,'perc': 0},
                {'stars': 4,'perc': 0},
                {'stars': 3,'perc': 0},
                {'stars': 2,'perc': 0},
                {'stars': 1,'perc': 0},
            ]
        return render(request, 'account/view.html', {'account':acc, 'cf_site_key': settings.CLOUDFLARE_SITE_KEY, 'range': range(1, 6), 'avg_rating': average_rating, 'stars_perc': star_percentages, 'all_reviews_len': all_reviews_len, 'reviews_all': reviews_all.order_by("-date_created")})
        
    def post(self, request, username):
        return add_review(request, username)
    


def save_review(request):
    review = Review(
        name = request.POST.get('name'),
        task_description = request.POST.get('task_description'),
        review = request.POST.get('review'),
        quality_of_service = request.POST.get('quality_of_service'),
        adherence_to_deadlines = request.POST.get('adherence_to_deadlines'),
        communication_responsiveness = request.POST.get('communication_responsiveness'),
        price_value_ratio = request.POST.get('price_value_ratio'),
        overall_satisfaction = request.POST.get('overall_satisfaction'),
        active = True,
        rating = 0
    )
    review.save()
    return review

def add_review_to_profile(review, user):
    Profile.objects.get(user=user).reviews.add(review)
        
def add_review(request, username):
    user = get_object_or_404(User, username=username)
    
    if not is_human(request):
        messages.error(request, _('Failed to pass the anti-bot protection.'))
        return redirect('account:view', username)
    
    review = save_review(request=request)
    add_review_to_profile(user=user, review=review)
    messages.success(request, _('Review has been successfully added.'))
    return redirect('account:view', username)
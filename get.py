import requests
import random

# request = requests.get('http://api.vk.com/')
# print(request.text)

class Bot():
    group_token = "97098cc901a2370b840e8c9ff1820f6c7afd1c6bb4f13180f5d7829fa828816550e5dc29333b636d57790"
    data = {
        'random_id' : None,
        'message' : None,
        'chat_id' : None,
        'v' : '5.126',
        'access_token' : group_token,
    }
    
    def send(self, ch_id, message):
        self.data['random_id'] = random.randint(10000000, 999999999)
        self.data['chat_id'] = ch_id
        self.data['message'] = message
        r = requests.post('http://vk-proxy.invilso.pp.ua/api/method/messages.send', data = self.data)
        return r

b = Bot()
x = b.send(2, 'mq mq mq')
print(x)